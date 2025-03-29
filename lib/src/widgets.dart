import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class CanvasItemWidget extends StatefulWidget {
  final CanvasItemState state;
  final Matrix4? parentTransform;

  const CanvasItemWidget({
    super.key,
    this.parentTransform,
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

  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    assert(
        widget.state.hasSize, 'CanvasItem ${widget.state} not been laid out');
    var innerSize = widget.state.innerSize;
    Matrix4 transform =
        widget.state.item.layoutData.computeTranslatedMatrix(widget.state);
    if (widget.parentTransform != null) {
      transform = widget.parentTransform! * transform;
    }
    Offset? editorOffset = widget.state.item.editorOffset;
    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    var editor = widget.state.editor;
    return IgnorePointer(
      ignoring: editorOffset != null,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Transform(
              transform: transform,
              child: AdaptiveSizedBox(
                size: innerSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTap: () {
                    widget.state.editor?.handleItemClick(widget.state);
                    print('tap ${widget.state.item.debugLabel}');
                  },
                  onPanStart: editor == null
                      ? null
                      : (details) {
                          _dragStart = details.globalPosition;
                        },
                  onPanUpdate: editor == null
                      ? null
                      : (details) {
                          if (_dragStart != null) {
                            editor.handleItemShift(
                                _dragStart!, details.globalPosition);
                          }
                        },
                  onPanEnd: editor == null
                      ? null
                      : (details) {
                          _dragStart = null;
                        },
                  onPanCancel: editor == null
                      ? null
                      : () {
                          _dragStart = null;
                        },
                  child: Container(
                    decoration: BoxDecoration(
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
          ),
          if (widget.state is CanvasObjectState)
            ListenableBuilder(
              listenable: Listenable.merge(
                  (widget.state as CanvasObjectState).children),
              builder: (context, child) {
                Polygon? polygon =
                    (widget.state as CanvasObjectState).item.clipContent
                        ? Polygon.fromRect(Offset.zero & innerSize)
                        : null;
                polygon = polygon?.transform(transform);
                return ClipPath(
                  clipper: polygon != null ? PathClipper(polygon.path) : null,
                  clipBehavior: polygon != null ? Clip.antiAlias : Clip.none,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      for (var child in (widget.state as CanvasObjectState)
                          .children
                          .sorted(_sortChildren))
                        CanvasItemWidget(
                          key: ValueKey(child),
                          parentTransform: transform,
                          state: child,
                        ),
                    ],
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
