import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class CanvasItemWidget extends StatefulWidget {
  final CanvasItemState state;
  // final Matrix4? parentTransform;
  final Matrix4? overrideTransform;

  const CanvasItemWidget({
    super.key,
    // this.parentTransform,
    this.overrideTransform,
    required this.state,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

int count = 0;

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  int _count = 0;
  @override
  void initState() {
    _count = count++;
    super.initState();
    widget.state.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant CanvasItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_update);
      widget.state.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {
      widget.state.forceRelayout();
    });
  }

  SelectionMoveControlSession? _moveControlSession;

  @override
  Widget build(BuildContext context) {
    assert(
        widget.state.hasSize, 'CanvasItem ${widget.state} not been laid out');
    var innerSize = widget.state.innerSize;
    Matrix4 transform = widget.overrideTransform ??
        widget.state.item.layoutData.computeTranslatedMatrix(widget.state);
    Offset? editorOffset = widget.state.editorOffset;
    if (editorOffset != null && widget.overrideTransform == null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    var editor = widget.state.editor;
    bool clipContent = widget.state is CanvasObjectState &&
        (widget.state as CanvasObjectState).item.clipContent;
    BorderRadiusGeometry? borderRadius = widget.state is CanvasObjectState
        ? (widget.state as CanvasObjectState).item.borderRadius
        : null;
    return FreeHitOpacity(
      opacity: widget.state.targetReparent == null ||
              widget.overrideTransform != null
          ? 1
          : 0,
      child: Transform(
        transform: transform,
        child: AdaptiveSizedBox(
          size: innerSize,
          child: FreeHitClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
            child: GroupWidget(
              passthrough: true,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    widget.state.editor?.handleItemClick(widget.state);
                  },
                  onPanStart: editor == null
                      ? null
                      : (details) {
                          editor.setToLocalSelection(widget.state);
                          Selection? local = editor.localSelection;
                          if (local != null) {
                            _moveControlSession = editor.startControlSession(
                                SelectionMoveControlSession(local, editor),
                                details.globalPosition);
                          }
                        },
                  onPanUpdate: editor == null
                      ? null
                      : (details) {
                          if (_moveControlSession != null) {
                            _moveControlSession = editor.updateControlSession(
                                _moveControlSession!, details.globalPosition);
                          }
                        },
                  onPanEnd: editor == null
                      ? null
                      : (details) {
                          if (_moveControlSession != null) {
                            editor.endControlSession(_moveControlSession!);
                            _moveControlSession = null;
                          }
                        },
                  onPanCancel: editor == null
                      ? null
                      : () {
                          if (_moveControlSession != null) {
                            editor.cancelControlSession(_moveControlSession!);
                            _moveControlSession = null;
                          }
                        },
                  child: widget.state.render(context),
                ),
                if (widget.state is CanvasObjectState) ...[
                  ListenableBuilder(
                    listenable: Listenable.merge(
                        (widget.state as CanvasObjectState).children),
                    builder: (context, child) {
                      return GroupWidget(
                        children: [
                          for (var child in (widget.state as CanvasObjectState)
                              .children
                              .sorted(_sortChildren))
                            CanvasItemWidget(
                              key: ValueKey(child),
                              state: child,
                            ),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable:
                        (widget.state as CanvasObjectState).targetDrop,
                    builder: (context, value, _) {
                      if (value == null) {
                        return GroupWidget();
                      }
                      return GroupWidget(
                        children: [
                          for (var group in value.groups.value)
                            for (var ghost in group.selectedItems)
                              Builder(
                                builder: (context) {
                                  var commonParent =
                                      ghost.findCommonParent(widget.state);
                                  if (commonParent == null) {
                                    return SizedBox.shrink();
                                  }
                                  Matrix4 reparentedTransform =
                                      commonParent.globalEditorTransform *
                                          ghost.getGlobalEditorTransformUntil(
                                              commonParent);
                                  return Transform(
                                    transform: Matrix4.inverted(
                                        widget.state.globalTransform),
                                    child: CanvasItemWidget(
                                      state: ghost,
                                      overrideTransform: reparentedTransform,
                                    ),
                                  );
                                },
                              )
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _sortChildren(CanvasItemState a, CanvasItemState b) {
    // if it has editorOffset, it should be on top
    if (a.editorOffset != null && b.editorOffset == null) {
      return 1;
    }
    if (a.editorOffset == null && b.editorOffset != null) {
      return -1;
    }
    return 0;
  }
}
