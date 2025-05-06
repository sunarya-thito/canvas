import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/grid/grid.dart';
import 'package:canvas/src/widget_util.dart';
import 'package:flutter/widgets.dart';

class _LayoutGridPainter extends CustomPainter {
  final CanvasEditor editor;
  final LayoutGrid layoutGrid;

  const _LayoutGridPainter({
    required this.layoutGrid,
    required this.editor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    layoutGrid.paint(editor, canvas, size);
  }

  @override
  bool shouldRepaint(covariant _LayoutGridPainter oldDelegate) {
    return oldDelegate.layoutGrid.shouldRepaint(layoutGrid) ||
        oldDelegate.editor != editor;
  }
}

class LayoutGridWidget extends StatelessWidget {
  final CanvasItemState state;
  final CanvasEditor editor;
  final Matrix4? overrideTransform;

  const LayoutGridWidget({
    super.key,
    required this.state,
    required this.editor,
    this.overrideTransform,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        var state = this.state;
        if (state is! CanvasParentState) {
          return SizedBox.shrink();
        }
        Matrix4 transform = overrideTransform ?? state.computeTransform();
        Offset? editorOffset = state.dragOffset;
        if (editorOffset != null && overrideTransform == null) {
          transform.translate(editorOffset.dx, editorOffset.dy);
        }
        bool clipContent = state.item.clipContent;
        return Visibility(
          visible: state.targetReparent == null || overrideTransform != null,
          child: Transform(
            transform: transform,
            child: AdaptiveSizedBox(
              size: state.size,
              child: FreeHitClipPath(
                clipper: clipContent
                    ? PathClipper(state.getPath())
                    : PathClipper(Path()),
                clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
                child: GroupWidget(
                  passthrough: true,
                  children: [
                    for (var layoutGrid in state.item.layoutGrids)
                      CustomPaint(
                        painter: _LayoutGridPainter(
                          editor: editor,
                          layoutGrid: layoutGrid,
                        ),
                      ),
                    IgnorePointer(
                      child: ListenableBuilder(
                        listenable: Listenable.merge(state.children),
                        builder: (context, child) {
                          return GroupWidget(
                            children: [
                              for (var child in state.children)
                                LayoutGridWidget(
                                  key: ValueKey(child),
                                  editor: editor,
                                  state: child,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (state.targetDrop != null)
                      GroupWidget(
                        children: [
                          for (var group in state.targetDrop!.groups)
                            for (var ghost in group.items)
                              Builder(
                                builder: (context) {
                                  var commonParent =
                                      ghost.findCommonParent(state);
                                  if (commonParent == null) {
                                    return SizedBox.shrink();
                                  }
                                  Matrix4 reparentedTransform = commonParent
                                          .computeEditorGlobalTransform() *
                                      ghost.computeEditorGlobalTransformUntil(
                                          commonParent);
                                  return Transform(
                                    transform: Matrix4.inverted(
                                        state.computeGlobalTransform()),
                                    child: LayoutGridWidget(
                                      state: ghost,
                                      editor: editor,
                                      overrideTransform: reparentedTransform,
                                    ),
                                  );
                                },
                              )
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
