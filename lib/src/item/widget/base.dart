import 'package:animation_kit/animation_kit.dart';
import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control/sessions/selection_move.dart';
import 'package:canvas/src/editor/widget/data.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/widgets.dart';

import '../../editor/selection/selection.dart';
import '../../widget_util.dart';

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
      builder: (context, child) {
        Matrix4 transform = this.transform ?? item.computeEditorTransform();
        var size = item.size;
        return FreeHitIgnorePointer(
          ignoring: item.item.locked,
          child: FreeHitOpacity(
            opacity: item.targetReparent == null || this.transform != null
                ? 1
                : item.targetReparent!.item.layout is FlexLayout
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
                child: AdaptiveSizedBox(
                  size: size,
                  child: child ?? const SizedBox.shrink(),
                ),
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
        if (editor.localSelection?.contains(item) == false) {
          editor.setToLocalSelection(item);
        }
        Selection? local = editor.localSelection;
        if (local != null) {
          var viewportSize = CanvasEditorWidgetData.find(context).viewportSize;
          editor.startControlSession(
              SelectionMoveControlSession(selection: local),
              details,
              viewportSize);
        }
      },
      onPanUpdate: (details) {
        var viewportSize = CanvasEditorWidgetData.find(context).viewportSize;
        editor.updateControlSession(details, viewportSize);
      },
      onPanEnd: (details) {
        var viewportSize = CanvasEditorWidgetData.find(context).viewportSize;
        editor.endControlSession(details, viewportSize);
      },
      onPanCancel: () {
        editor.cancelControlSession();
      },
      child: child,
    );
  }
}
