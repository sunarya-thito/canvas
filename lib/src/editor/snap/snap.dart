import 'dart:math';

import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

typedef SnappingLineVisitor = bool Function(SnappingLine line);
typedef SnapAnchorVisitor = bool Function(SnapAnchor point);
typedef SnappingPointVisitor = bool Function(Offset point);

class SnappingEntry {
  final SnapAnchor sourceAnchor;
  final SnappingLine sourceLine;
  final SnapAnchor targetAnchor;
  final SnappingLine targetLine;
  final Offset snapDelta; // delta to move the source to the target
  final double distance; // distance between the source and target lines

  const SnappingEntry({
    required this.sourceAnchor,
    required this.sourceLine,
    required this.targetAnchor,
    required this.targetLine,
    required this.snapDelta,
    required this.distance,
  });

  @override
  String toString() {
    return 'SnappingEntry{sourceAnchor: $sourceAnchor, sourceLine: $sourceLine, targetAnchor: $targetAnchor, targetLine: $targetLine, snapDelta: $snapDelta, distance: $distance}';
  }
}

class SnappingResult {
  final List<SnappingEntry> entries;
  final Offset snapDelta;

  const SnappingResult({
    required this.entries,
    required this.snapDelta,
  });
}

class SnappingConfiguration {
  static const List<double> defaultAngleSnapping = [
    0,
    45 / 180 * pi,
    90 / 180 * pi,
    135 / 180 * pi,
    180 / 180 * pi,
    225 / 180 * pi,
    270 / 180 * pi,
    315 / 180 * pi,
    360 / 180 * pi,
  ];
  final double
      snappingDistance; // must be scaled with viewport zoom since we're at it
  final double angleSnappingDistance; // in radians
  final bool enableSnapping;
  final List<double> angleSnapping;
  final bool rotatedSnap;

  const SnappingConfiguration({
    this.enableSnapping = true,
    this.snappingDistance = 10,
    this.angleSnappingDistance = 5 / 180 * pi,
    this.angleSnapping = defaultAngleSnapping,
    this.rotatedSnap = true,
  });

  double snapRotation(double angle) {
    if (angleSnapping.isEmpty) return angle;
    double wrapped = wrapRotation(angle);
    for (var snap in angleSnapping) {
      double delta = wrapped - snap;
      if (delta.abs() < angleSnappingDistance) {
        return angle - delta;
      }
    }
    return angle;
  }
}

class SnappingLine {
  final double offset;
  final Axis direction; // horizontal = left to right, vertical = top to bottom

  const SnappingLine({
    required this.offset,
    required this.direction,
  });

  double distanceTo(SnappingLine line) {
    if (direction == line.direction) {
      return (offset - line.offset).abs();
    } else {
      return double.infinity;
    }
  }

  // RETURNS DELTA
  Offset snapToLine(SnappingLine line) {
    if (direction == line.direction) {
      double delta = offset - line.offset;
      if (direction == Axis.vertical) {
        return Offset(delta, 0);
      } else {
        return Offset(0, delta);
      }
    } else {
      return Offset.zero;
    }
  }

  @override
  String toString() {
    return 'SnappingLine{offset: $offset, direction: $direction}';
  }
}

abstract class SnapAnchor {
  const SnapAnchor();

  String? get debugOwner => null;

  void visitLines(SnappingLineVisitor visitor);

  SnapAnchor shift(Offset offset);

  bool canSnapInto(SnapAnchor other) => true;
}
