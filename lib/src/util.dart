import 'dart:math';
import 'dart:ui';

Offset rotatePoint(Offset point, double angle) {
  final double cosAngle = cos(angle);
  final double sinAngle = sin(angle);
  return Offset(
    point.dx * cosAngle - point.dy * sinAngle,
    point.dx * sinAngle + point.dy * cosAngle,
  );
}

Offset proportionalDelta(Offset offset, double aspectRatio) {
  double dx = offset.dx;
  double dy = offset.dy;
  return Offset(min(dx, dy * aspectRatio), min(dy, dx / aspectRatio));
}

extension OffsetExtension on Offset {
  Offset multiply(Offset other) {
    return Offset(dx * other.dx, dy * other.dy);
  }

  Offset onlyX() {
    return Offset(dx, 0);
  }

  Offset onlyY() {
    return Offset(0, dy);
  }

  Offset divideBy(Offset other) {
    return Offset(dx / other.dx, dy / other.dy);
  }
}
