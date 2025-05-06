import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

extension SizeExtension on Size {
  bool containsIgnoreSign(Offset position) {
    double width = this.width;
    double height = this.height;
    if (width.isNaN) {
      width = 0;
    }
    if (height.isNaN) {
      height = 0;
    }
    bool flipHorizontal = width.isNegative;
    bool flipVertical = height.isNegative;
    double dx = position.dx;
    double dy = position.dy;
    if (flipHorizontal) {
      dx = -dx;
      width = -width;
    }
    if (flipVertical) {
      dy = -dy;
      height = -height;
    }
    return dx >= 0 && dy >= 0 && dx <= width && dy <= height;
  }
}

Matrix4 computeShearMatrix(Offset shear) {
  final shearMatrix = Matrix4.identity()
    ..setEntry(0, 1, tan(shear.dx))
    ..setEntry(1, 0, tan(shear.dy));
  final scaleMatrix = Matrix4.identity()
    ..setEntry(1, 1, cos(shear.dx))
    ..setEntry(0, 0, cos(shear.dy));
  return shearMatrix * scaleMatrix;
}

Offset computeShearFromMatrix(Matrix4 matrix) {
  final shearX = atan(matrix.entry(0, 1) / matrix.entry(1, 1));
  final shearY = atan(matrix.entry(1, 0) / matrix.entry(0, 0));
  return Offset(shearX, shearY);
}

double wrapRotation(double angle) {
  const tau = pi * 2;
  return (angle % tau + tau) % tau;
}

Matrix4 computeOrigin(Matrix4 transform, Offset origin) {
  final translateToOrigin = Matrix4.identity()
    ..setTranslationRaw(-origin.dx, -origin.dy, 0);
  final translateBack = Matrix4.identity()
    ..setTranslationRaw(origin.dx, origin.dy, 0);
  return translateBack * transform * translateToOrigin;
}

Offset rotatePoint(Offset point, double angle, [Offset origin = Offset.zero]) {
  final cosAngle = cos(angle);
  final sinAngle = sin(angle);
  final dx = point.dx - origin.dx;
  final dy = point.dy - origin.dy;
  final x = origin.dx + cosAngle * dx - sinAngle * dy;
  final y = origin.dy + sinAngle * dx + cosAngle * dy;
  return Offset(x, y);
}

Offset scalePoint(Offset point, Offset scale, [Offset origin = Offset.zero]) {
  final dx = (point.dx - origin.dx) * scale.dx + origin.dx;
  final dy = (point.dy - origin.dy) * scale.dy + origin.dy;
  return Offset(dx, dy);
}

Offset transformOffset(Offset point, Matrix4 transform,
    [Offset origin = Offset.zero]) {
  final vector = Vector3(point.dx - origin.dx, point.dy - origin.dy, 0);
  final transformed = transform.perspectiveTransform(vector);
  return Offset(transformed.x + origin.dx, transformed.y + origin.dy);
}

Size transformSize(Size size, Matrix4 transform,
    [Offset origin = Offset.zero]) {
  final vector = Vector3(size.width - origin.dx, size.height - origin.dy, 0);
  final transformed = transform.perspectiveTransform(vector);
  return Size(transformed.x + origin.dx, transformed.y + origin.dy);
}

double distanceBetweenRects(Rect a, Rect b) {
  double dx = 0.0;
  double dy = 0.0;

  if (a.right < b.left) {
    dx = b.left - a.right;
  } else if (b.right < a.left) {
    dx = a.left - b.right;
  }

  if (a.bottom < b.top) {
    dy = b.top - a.bottom;
  } else if (b.bottom < a.top) {
    dy = a.top - b.bottom;
  }

  return sqrt(dx * dx + dy * dy);
}
