import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';

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
    if (!visitor(SnappingLine(offset: point.dx, direction: Axis.horizontal))) {
      return;
    }
    if (!visitor(SnappingLine(offset: point.dy, direction: Axis.vertical))) {
      return;
    }
  }
}
