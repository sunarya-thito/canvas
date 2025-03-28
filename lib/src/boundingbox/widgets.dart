import 'package:canvas/canvas.dart';
import 'package:canvas/src/actions.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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
