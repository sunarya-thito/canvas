import 'package:canvas/canvas.dart';
import 'package:canvas/src/actions.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Offset _handleDragAttempt(BuildContext context, CanvasObjectState parent,
    CanvasItemState dragged, CanvasItemState dragTarget, Offset localPosition) {
  var result = parent.item.layout
      .handleDragAttempt(parent, dragged, dragTarget, localPosition);
  print('result: $result');
  if (result is ReInsertDragResult) {
    var beforeThis = result.beforeThis;
    var direction = result.direction;
    print('target: ${beforeThis?.item.debugLabel}');
    double adjustment = 0;
    List<CanvasItem> children = List.of(parent.item.children);
    if (beforeThis == null) {
      // insert at the end
      children.remove(dragged.item);
      children.add(dragged.item);
    } else {
      children.insert(
        children.indexOf(beforeThis.item),
        dragged.item,
      );
      children.remove(dragged.item);
    }
    print('newChildren: ${children.map((e) => e.debugLabel)}');
    var actionResult = Actions.invoke(context,
        CanvasUpdateChildrenIntent(parent: parent.item, children: children));
    print('invoke result: $actionResult');
    if (actionResult == true) {
      Offset adjustmentOffset = direction == Axis.horizontal
          ? Offset(adjustment, 0)
          : Offset(0, adjustment);
      return adjustmentOffset;
    }
  }
  return Offset.zero;
}

class CanvasBoundingBoxWidget extends StatefulWidget {
  final CanvasItemState state;
  final Matrix4? parentTransform;

  const CanvasBoundingBoxWidget(
      {super.key, required this.state, this.parentTransform});

  @override
  State<CanvasBoundingBoxWidget> createState() =>
      _CanvasBoundingBoxWidgetState();
}

class _CanvasBoundingBoxWidgetState extends State<CanvasBoundingBoxWidget> {
  @override
  void dispose() {
    print('boundingbox disposed: ${widget.state.item.debugLabel}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is CanvasObjectState) {
      // for (var child in (widget.state as CanvasObjectState).children) {

      // }
      print(
          '${widget.state.item.debugLabel}: ${(widget.state as CanvasObjectState).children.map((e) => e.item.debugLabel)}');
    }
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, child) {
        Offset position = widget.state.parentData.position;
        Offset? editorOffset = widget.state.item.editorOffset;
        Matrix4 parentTransform =
            widget.parentTransform?.clone() ?? Matrix4.identity();

        parentTransform.translate(position.dx, position.dy);
        Matrix4 transform = widget.state.item.layoutData.computeMatrix(
            widget.state, widget.state.size,
            parentMatrix: parentTransform);

        if (editorOffset != null) {
          transform.translate(editorOffset.dx, editorOffset.dy);
        }

        var innerSize = widget.state.item.layoutData
            .computeInnerSize(widget.state, widget.state.size);
        return GroupData(
          position: Offset.zero,
          child: GroupWidget(
            size: widget.state.size,
            children: [
              if (widget.state.item is! CanvasRoot)
                IgnorePointer(
                  child: CustomPaint(
                    size: innerSize,
                    painter: BoundingBoxPainter(
                      transform: transform,
                      borderColor: Color.fromARGB(255, 0, 0, 0),
                      borderWidth: 1,
                    ),
                  ),
                ),
              if (widget.state.item is! CanvasRoot)
                Transform(
                  transform: transform,
                  child: SizedBox.fromSize(
                    size: innerSize,
                    child: MetaData(
                      metaData: widget.state,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          Offset delta = details.delta;
                          var parent = widget.state.parent;
                          if (parent is CanvasObjectState) {
                            var boxData = BoundingBoxData.findInLocation(
                                context, details.globalPosition);
                            if (boxData != null) {
                              var adjustment = _handleDragAttempt(
                                  context,
                                  parent,
                                  widget.state,
                                  boxData.state,
                                  boxData.localPosition);
                              delta += adjustment;
                            }
                          }
                          widget.state.item.editorOffset =
                              (widget.state.item.editorOffset ?? Offset.zero) +
                                  delta;
                        },
                        onPanCancel: () =>
                            widget.state.item.editorOffset = null,
                        onPanEnd: (details) {
                          Offset delta =
                              widget.state.item.editorOffset ?? Offset.zero;
                          widget.state.item.editorOffset = null;
                          // set the alignment to topLeft because
                          // delta does not have size to be aligned to
                          Matrix4 selfMatrix = widget.state.item.layoutData
                              .computeMatrix(widget.state, widget.state.size,
                                  alignment: Alignment.topLeft);
                          delta = transformOffset(delta, selfMatrix);
                          Actions.invoke(
                            context,
                            CanvasUpdateLayoutDataIntent(
                              item: widget.state.item,
                              layoutData:
                                  widget.state.item.layoutData.drag(delta),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (widget.state is CanvasObjectState)
                for (var child in (widget.state as CanvasObjectState).children)
                  CanvasBoundingBoxWidget(
                    key: ValueKey(child),
                    state: child,
                    parentTransform: transform,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class CanvasBoundingBoxMetadataWidget extends StatelessWidget {
  final CanvasItemState state;

  const CanvasBoundingBoxMetadataWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        assert(state.hasSize, 'CanvasItem $state not been laid out');
        var innerSize =
            state.item.layoutData.computeInnerSize(state, state.size);
        Matrix4 transform =
            state.item.layoutData.computeMatrix(state, state.size);
        Offset position = state.parentData.position;
        return GroupData(
          position: position,
          child: GroupWidget(
            size: state.size,
            children: [
              Transform(
                transform:
                    state.item.layoutData.computeBoundingBoxMatrix(state.size),
                child: SizedBox(
                  width: innerSize.width,
                  height: innerSize.height,
                  child: NonOpaqueMetaData(
                    opaque: false,
                    behavior: HitTestBehavior.translucent,
                    metaData: BoundingBoxData(state),
                  ),
                ),
              ),
              if (state is CanvasObjectState)
                Transform(
                  transform: transform,
                  child: GroupWidget(size: innerSize, children: [
                    ...(state as CanvasObjectState).children.map((child) {
                      return CanvasBoundingBoxMetadataWidget(
                        state: child,
                      );
                    }),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class FoundBoundingBoxData {
  final CanvasItemState state;
  final Offset position;
  final Offset localPosition;

  const FoundBoundingBoxData(
      {required this.state,
      required this.position,
      required this.localPosition});

  @override
  String toString() {
    return 'FoundBoundingBoxData(state: $state, position: $position, localPosition: $localPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoundBoundingBoxData &&
        other.state == state &&
        other.position == position &&
        other.localPosition == localPosition;
  }

  @override
  int get hashCode {
    return Object.hash(state, position, localPosition);
  }
}

class BoundingBoxData {
  static FoundBoundingBoxData? findInLocation(
      BuildContext context, Offset position) {
    var result = HitTestResult();
    WidgetsBinding.instance
        .hitTestInView(result, position, View.of(context).viewId);
    for (var entry in result.path) {
      if (entry.target is RenderMetaData) {
        var metaData = (entry.target as RenderMetaData).metaData;
        if (metaData is BoundingBoxData && entry is BoxHitTestEntry) {
          return FoundBoundingBoxData(
            state: metaData.state,
            position: position,
            localPosition: entry.localPosition,
          );
        }
      }
    }
    return null;
  }

  final CanvasItemState state;

  BoundingBoxData(this.state);

  @override
  String toString() {
    return 'BoundingBoxData(state: $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BoundingBoxData && other.state == state;
  }

  @override
  int get hashCode {
    return state.hashCode;
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Matrix4 transform;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;

  BoundingBoxPainter({
    required this.transform,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var borderColor = this.borderColor;
    var fillColor = this.fillColor;
    var borderWidth = this.borderWidth;
    final topLeft = Offset(0, 0);
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);

    final transformedTopLeft = transformOffset(topLeft, transform);
    final transformedTopRight = transformOffset(topRight, transform);
    final transformedBottomLeft = transformOffset(bottomLeft, transform);
    final transformedBottomRight = transformOffset(bottomRight, transform);

    final boundingBoxPath = Path()
      ..moveTo(transformedTopLeft.dx, transformedTopLeft.dy)
      ..lineTo(transformedTopRight.dx, transformedTopRight.dy)
      ..lineTo(transformedBottomRight.dx, transformedBottomRight.dy)
      ..lineTo(transformedBottomLeft.dx, transformedBottomLeft.dy)
      ..close();

    if (fillColor != null) {
      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(boundingBoxPath, paint);
    }

    if (borderColor != null && borderWidth != null) {
      final paint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(boundingBoxPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

class BoundingBoxDebugger extends StatefulWidget {
  final Widget child;

  const BoundingBoxDebugger({super.key, required this.child});

  @override
  State<BoundingBoxDebugger> createState() => _BoundingBoxDebuggerState();
}

class _BoundingBoxDebuggerState extends State<BoundingBoxDebugger> {
  Offset? _position;
  CanvasItemState? _hoveredItem;
  FoundBoundingBoxData? _boundingBoxData;

  CanvasItemState? _findItemState(Offset position) {
    var result = HitTestResult();
    WidgetsBinding.instance
        .hitTestInView(result, position, View.of(context).viewId);
    for (var entry in result.path) {
      if (entry.target is RenderMetaData) {
        var metaData = (entry.target as RenderMetaData).metaData;
        if (metaData is CanvasItemState) {
          return metaData;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        setState(() {
          _position = event.localPosition;
          _hoveredItem = _findItemState(event.position);
          _boundingBoxData =
              BoundingBoxData.findInLocation(context, event.position);
        });
      },
      onExit: (event) {
        setState(() {
          _position = null;
          _hoveredItem = null;
        });
      },
      onHover: (event) {
        setState(() {
          _position = event.localPosition;
          _hoveredItem = _findItemState(event.position);
          _boundingBoxData =
              BoundingBoxData.findInLocation(context, event.position);
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_position != null)
            Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: IgnorePointer(
                child: Container(
                  color: Color.fromARGB(50, 0, 0, 255),
                  constraints: BoxConstraints(
                    maxWidth: 400,
                  ),
                  child: Text(
                    buildDebugText(),
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String buildDebugText() {
    List<String> lines = [];
    if (_position != null) {
      lines.add('Position: (${_position!.dx}, ${_position!.dy})');
    }
    if (_hoveredItem != null) {
      lines.add('Hovered Item: $_hoveredItem');
    }
    if (_boundingBoxData != null) {
      lines.add('BoundingBoxData: $_boundingBoxData');
    }
    return lines.join('\n');
  }
}
