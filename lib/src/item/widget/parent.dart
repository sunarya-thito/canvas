import 'package:canvas/canvas.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:canvas/src/widget_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class CanvasParentWidget extends StatelessWidget {
  final CanvasParentState item;
  final Widget? child;

  const CanvasParentWidget({
    super.key,
    required this.item,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final targetDrop = item.targetDrop;
    return ListenableBuilder(
      listenable: item,
      builder: (context, child) {
        return FreeHitClipPath(
          clipper: item.item.clipContent
              ? PathClipper(item.getPath())
              : PathClipper(Path()),
          clipBehavior: item.item.clipContent ? Clip.antiAlias : Clip.none,
          child: GroupWidget(
            children: [
              if (child != null) child,
              for (var child in item.children.sorted(_sortChildren))
                child.render(context),
              if (item.item.layout is! FlexLayout && targetDrop != null)
                for (var group in targetDrop.groups)
                  for (var ghost in group.items)
                    Builder(
                      builder: (context) {
                        var commonParent = ghost.findCommonParent(item);
                        if (commonParent == null) {
                          return const SizedBox.shrink();
                        }
                        Matrix4 reparentedTransform =
                            commonParent.computeEditorGlobalTransform() *
                                ghost.computeEditorGlobalTransformUntil(
                                    commonParent);
                        return Transform(
                          transform: Matrix4.inverted(
                              item.computeEditorGlobalTransform()),
                          child: ghost.render(context,
                              transform: reparentedTransform),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}

int _sortChildren(CanvasItemState a, CanvasItemState b) {
  // if it has editorOffset, it should be on top
  if (a.dragOffset != null && b.dragOffset == null) {
    return 1;
  }
  if (a.dragOffset == null && b.dragOffset != null) {
    return -1;
  }
  return 0;
}
