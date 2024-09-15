import 'dart:math';

import 'package:flutter/rendering.dart';

class CanvasTransform {
  final Offset offset;
  final Size scale;
  final double rotation;
  final Alignment alignment;
  final Size size;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.scale = const Size(1.0, 1.0),
    this.rotation = 0.0,
    this.alignment = Alignment.center,
    this.size = Size.zero,
  });

  CanvasTransform copyWith({
    Offset? offset,
    Size? scale,
    double? rotation,
    Alignment? alignment,
    Size? size,
  }) {
    return CanvasTransform(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      alignment: alignment ?? this.alignment,
      size: size ?? this.size,
    );
  }

  Size get scaledSize =>
      Size(size.width * scale.width, size.height * scale.height);

  Matrix4 get matrix {
    final matrix = Matrix4.identity();
    final origin = alignment.alongSize(size);
    matrix.translate(offset.dx, offset.dy);
    matrix.rotateZ(rotation);
    matrix.translate(-origin.dx, -origin.dy);
    matrix.scale(scale.width, scale.height);
    return matrix;
  }

  Matrix4 get nonScalingMatrix {
    final matrix = Matrix4.identity();
    final origin = alignment.alongSize(size);
    matrix.translate(offset.dx, offset.dy);
    matrix.rotateZ(rotation);
    matrix.translate(-origin.dx, -origin.dy);
    return matrix;
  }
}

Offset _rotatePoint(Offset point, double angle) {
  final x = point.dx;
  final y = point.dy;
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    x * cosA - y * sinA,
    x * sinA + y * cosA,
  );
}
