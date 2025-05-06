import 'package:canvas/src/editor/ruler/ruler.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';

class CanvasRulerSnapAnchor extends SnapAnchor {
  final double offset;
  final Axis direction;
  final CanvasRulerCrossLineVisitor? crossLineVisitor;

  const CanvasRulerSnapAnchor({
    required this.offset,
    required this.direction,
    this.crossLineVisitor, // only needed for one axis
  });

  @override
  SnapAnchor shift(Offset offset) {
    return CanvasRulerSnapAnchor(
      offset:
          this.offset + (direction == Axis.horizontal ? offset.dy : offset.dx),
      direction: direction,
      crossLineVisitor: crossLineVisitor,
    );
  }

  @override
  void visitLines(SnappingLineVisitor visitor) {
    visitor(SnappingLine(offset: offset, direction: direction));
  }

  @override
  bool canSnapInto(SnapAnchor other) {
    return other is! CanvasRulerSnapAnchor;
  }
}
