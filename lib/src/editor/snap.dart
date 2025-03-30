import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

typedef SnappingLineVisitor = bool Function(SnappingLine line);
typedef SnappingPointVisitor = bool Function(SnappingPoint point);

class SnappingConfiguration {
  static const List<double> defaultAngleSnapping = [
    0,
    pi / 6, // deg: 30
    pi / 4, // deg: 45
    pi / 3, // deg: 60
    pi / 2, // deg: 90
  ];
  final double
      snappingDistance; // must be scaled with viewport zoom since we're at it
  // final List<double> angleSnapping = [
  //   0,
  //   pi / 4, // deg: 45
  //   pi / 2, // deg: 90
  // ];
  final List<double> angleSnapping;
  final bool rotatedSnap;

  const SnappingConfiguration({
    this.snappingDistance = 10,
    this.angleSnapping = defaultAngleSnapping,
    this.rotatedSnap = true,
  });
}

class SnappingResult {
  final Offset newOffset;
  final double angle;

  const SnappingResult({
    required this.newOffset,
    this.angle = 0,
  });
}

class SnappingLine {
  final Offset point;
  final double angle;

  const SnappingLine({
    required this.point,
    required this.angle,
  });

  double distanceTo(Offset target, [double? angle]) {
    if (angle != null && angle != this.angle) {
      return double.infinity;
    }
    double dx = target.dx - point.dx;
    double dy = target.dy - point.dy;

    double t = dx * cos(this.angle) + dy * sin(this.angle);

    double snappedX = point.dx + t * cos(this.angle);
    double snappedY = point.dy + t * sin(this.angle);

    return sqrt(pow(snappedX - target.dx, 2) + pow(snappedY - target.dy, 2));
  }

  Offset snapToLine(Offset target) {
    double dx = target.dx - point.dx;
    double dy = target.dy - point.dy;

    double t = dx * cos(angle) + dy * sin(angle);

    double snappedX = point.dx + t * cos(angle);
    double snappedY = point.dy + t * sin(angle);

    return Offset(snappedX, snappedY);
  }
}

abstract class SnappingPoint {
  const SnappingPoint();

  // point is in global viewport coordinates (not app global coordinates)
  SnappingResult? computeSnapping(
    CanvasEditorHandler editor,
    SnappingPoint other,
    SnappingConfiguration configuration,
  );

  void visitLines(SnappingLineVisitor visitor);
}

class AbsoluteSnappingPoint extends SnappingPoint {
  // point is in global viewport coordinates (local to root)
  final Offset point;
  // angle is maxed out at 90deg (one quadrant)
  // angle is in radians
  final double angle;

  const AbsoluteSnappingPoint({
    required this.point,
    this.angle = 0,
  });

  @override
  void visitLines(SnappingLineVisitor visitor) {
    if (!visitor(SnappingLine(point: point, angle: 0))) return;
    if (!visitor(SnappingLine(point: point, angle: angle % pi))) return;
    if (angle != 0) {
      if (!visitor(SnappingLine(point: point, angle: (angle + pi / 2) % pi))) {
        return;
      }
      visitor(SnappingLine(point: point, angle: (angle + pi) % pi));
    }
  }

  @override
  SnappingResult? computeSnapping(
    CanvasEditorHandler editor,
    SnappingPoint other,
    SnappingConfiguration configuration,
  ) {
    double targetDistance =
        configuration.snappingDistance / editor.transform.zoom;
    SnappingResult? result;
    other.visitLines(
      (line) {
        if (line.angle != 0 && !configuration.rotatedSnap) {
          return true;
        }
        double distance = line.distanceTo(point);
        if (distance <= targetDistance) {
          result = SnappingResult(
            newOffset: line.snapToLine(point),
            angle: line.angle,
          );
          return false;
        }
        return true;
      },
    );
    return result;
  }
}

class CanvasItemSnappingPoint extends AbsoluteSnappingPoint {
  final CanvasItemState item;

  const CanvasItemSnappingPoint({
    required this.item,
    required super.point,
    super.angle,
  });

  @override
  SnappingResult? computeSnapping(CanvasEditorHandler editor,
      SnappingPoint other, SnappingConfiguration configuration) {
    if (other is CanvasItemSnappingPoint && angle != 0) {
      var otherParent = other.item.parent;
      if (otherParent != item.parent) {
        return null;
      }
    }
    return super.computeSnapping(editor, other, configuration);
  }

  @override
  void visitLines(SnappingLineVisitor visitor) {
    if (!visitor(SnappingLine(point: point, angle: 0))) return;
    if (!visitor(SnappingLine(point: point, angle: pi / 2))) return;
    if (angle != 0) {
      visitor(SnappingLine(point: point, angle: angle % pi));
    }
  }

  @override
  String toString() {
    return 'CanvasItemSnappingPoint{item: $item, point: $point, angle: $angle}';
  }
}

class SelectionSnappingPoint extends AbsoluteSnappingPoint {
  final SelectionGroup group;

  const SelectionSnappingPoint({
    required this.group,
    required super.point,
  });
}
