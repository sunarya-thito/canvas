import 'package:flutter/widgets.dart';

abstract class SnappingPoint {
  const SnappingPoint();

  Offset? getSnappingOffset(Offset offset);
}

class AbsoluteSnappingPoint {
  // point is in global viewport coordinates (local to root)
  final Offset point;
  final double angle;

  const AbsoluteSnappingPoint({
    required this.point,
    this.angle = 0,
  });
}
