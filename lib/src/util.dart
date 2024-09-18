import 'dart:math';
import 'dart:ui';

Offset rotatePoint(Offset point, double angle) {
  final c = cos(angle);
  final s = sin(angle);
  return Offset(
    point.dx * c - point.dy * s,
    point.dx * s + point.dy * c,
  );
}
