import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:canvas/src/selection/selection.dart';
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
  // final List<double> angleSnapping = [
  //   0,
  //   pi / 4, // deg: 45
  //   pi / 2, // deg: 90
  // ];
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

class AbsoluteSnapAnchor extends SnapAnchor {
  // point is in global viewport coordinates (local to root)
  final Offset point;
  @override
  final String? debugOwner;

  const AbsoluteSnapAnchor({
    required this.point,
    this.debugOwner,
  });

  @override
  SnapAnchor shift(Offset offset) {
    return AbsoluteSnapAnchor(
      point: point + offset,
    );
  }

  @override
  void visitLines(SnappingLineVisitor visitor) {
    if (!visitor(SnappingLine(offset: point.dy, direction: Axis.horizontal))) {
      return;
    }
    if (!visitor(SnappingLine(offset: point.dx, direction: Axis.vertical))) {
      return;
    }
  }
}

class CanvasItemSnapAnchor extends AbsoluteSnapAnchor {
  final CanvasItemState item;

  const CanvasItemSnapAnchor({
    required this.item,
    required super.point,
  });

  @override
  SnapAnchor shift(Offset offset) {
    return CanvasItemSnapAnchor(
      item: item,
      point: point + offset,
    );
  }

  @override
  String? get debugOwner => item.item.debugLabel;

  @override
  String toString() {
    return 'CanvasItemSnapAnchor{item: $item, point: $point}';
  }
}

class SelectionSnapAnchor extends AbsoluteSnapAnchor {
  final SelectionGroup group;

  const SelectionSnapAnchor({
    required this.group,
    required super.point,
  });

  @override
  SnapAnchor shift(Offset offset) {
    return SelectionSnapAnchor(
      group: group,
      point: point + offset,
    );
  }

  @override
  String toString() {
    return 'SelectionSnapAnchor{group: $group, point: $point}';
  }
}

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
