import 'package:animation_kit/animation_kit.dart';
import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasItemWidget extends StatelessWidget {
  final CanvasItemState item;
  final Widget? child;
  final Matrix4? transform;

  const CanvasItemWidget({
    super.key,
    required this.item,
    this.child,
    this.transform,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: item,
      child: child,
      builder: (context, child) {
        Matrix4 transform = this.transform ?? item.computeEditorTransform();
        return FreeHitIgnorePointer(
          ignoring: item.item.locked,
          child: FreeHitOpacity(
            opacity: item.targetReparent is! CanvasFrameState ||
                    this.transform != null
                ? 1
                : (item.targetReparent as CanvasFrameState).item.layout
                        is FlexLayout
                    ? 0.5
                    : 0,
            child: AnimatedValueBuilder(
              value: item.reorderOffsets,
              lerp: Offset.lerp,
              duration: item.reorderOffsets == null
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: value ?? Offset.zero,
                  child: child!,
                );
              },
              child: Transform(
                transform: transform,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CanvasItemEditorWidget extends StatelessWidget {
  final CanvasItemState item;
  final CanvasEditor editor;
  final Widget? child;

  const CanvasItemEditorWidget({
    super.key,
    required this.item,
    required this.editor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        editor.handleItemClick(item);
      },
      onPanStart: (details) {
        if (editor.localSelection?.contains(item) != true) {
          editor.setToLocalSelection(item);
        }
        Selection? local = editor.localSelection;
        if (local != null) {
          final editorData = CanvasEditorWidgetData.find(context);
          editor.startControlSession(
              SelectionMoveControlSession(selection: local),
              editorData.globalToLocal(details.globalPosition),
              editorData.viewportSize);
        }
      },
      onPanUpdate: (details) {
        final editorData = CanvasEditorWidgetData.find(context);
        editor.updateControlSession(
            editorData.globalToLocal(details.globalPosition),
            editorData.viewportSize);
      },
      onPanEnd: (details) {
        editor.endControlSession();
      },
      onPanCancel: () {
        editor.cancelControlSession();
      },
      child: child,
    );
  }
}
