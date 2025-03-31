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

  const CanvasItemWidget({
    super.key,
    // this.parentTransform,
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

  Color _computeRandomColor(int hash) {
    Random random = Random(hash);
    return Color.fromARGB(
      255,
      random.nextInt(255),
      random.nextInt(255),
      random.nextInt(255),
    );
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
    Matrix4 transform =
        widget.state.item.layoutData.computeTranslatedMatrix(widget.state);
    Offset? editorOffset = widget.state.item.editorOffset;
    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    var editor = widget.state.editor;
    bool clipContent = widget.state is CanvasObjectState &&
        (widget.state as CanvasObjectState).item.clipContent;
    BorderRadiusGeometry? borderRadius = widget.state is CanvasObjectState
        ? (widget.state as CanvasObjectState).item.borderRadius
        : null;
    return Transform(
      transform: transform,
      child: GroupWidget(
        children: [
          AdaptiveSizedBox(
            size: innerSize,
            child: FreeHitClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: widget.state is CanvasObjectState
                        ? (widget.state as CanvasObjectState).item.borderRadius
                        : null,
                    color: _computeRandomColor(_count),
                    border: Border.all(
                      color: _computeRandomColor(_count + 1),
                      width: 3,
                    ),
                  ),
                  child: Text(
                      '${widget.state.item.debugLabel}(${widget.state.size.width}, ${widget.state.size.height}))'),
                ),
              ),
            ),
          ),
          if (widget.state is CanvasObjectState)
            ListenableBuilder(
              listenable: Listenable.merge(
                  (widget.state as CanvasObjectState).children),
              builder: (context, child) {
                return AdaptiveSizedBox(
                  size: innerSize,
                  child: FreeHitClipRRect(
                    borderRadius: borderRadius ?? BorderRadius.zero,
                    clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
                    child: GroupWidget(
                      children: [
                        for (var child in (widget.state as CanvasObjectState)
                            .children
                            .sorted(_sortChildren))
                          CanvasItemWidget(
                            key: ValueKey(child),
                            state: child,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  int _sortChildren(CanvasItemState a, CanvasItemState b) {
    // if it has editorOffset, it should be on top
    if (a.item.editorOffset != null && b.item.editorOffset == null) {
      return 1;
    }
    if (a.item.editorOffset == null && b.item.editorOffset != null) {
      return -1;
    }
    return 0;
  }
}
