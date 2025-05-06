import 'dart:math';

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
    pi / 6, // deg: 30
    pi / 4, // deg: 45
    pi / 3, // deg: 60
    pi / 2, // deg: 90
  ];
  final double
      snappingDistance; // must be scaled with viewport zoom since we're at it
  final bool enableSnapping;
  final List<double> angleSnapping;
  final bool rotatedSnap;

  const SnappingConfiguration({
    this.enableSnapping = true,
    this.snappingDistance = 10,
    this.angleSnapping = defaultAngleSnapping,
    this.rotatedSnap = true,
  });
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
