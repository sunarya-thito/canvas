import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasLayoutData {
  final TextDirection? textDirection;
  final double? rotation;
  final Offset? scale;

  const CanvasLayoutData({
    this.textDirection,
    this.rotation,
    this.scale,
  });

  Size computeInnerSize(Size outerSize,
      [Alignment alignment = Alignment.center]) {
    var width = outerSize.width;
    var height = outerSize.height;
    var scale = this.scale ?? const Offset(1, 1);

    // Apply scaling
    var scaledWidth = width / scale.dx;
    var scaledHeight = height / scale.dy;

    return Size(scaledWidth, scaledHeight);
  }

  Matrix4 computeMatrix(Size size,
      {Alignment alignment = Alignment.center, Matrix4? parentMatrix}) {
    Matrix4 matrix = Matrix4.identity();

    var scale = this.scale ?? const Offset(1, 1);
    var rotation = this.rotation ?? 0;

    Size innerSize = computeInnerSize(size, alignment);
    Offset origin = alignment.alongSize(innerSize);
    matrix.translate(origin.dx, origin.dy);
    matrix.rotateZ(rotation);
    matrix.translate(-origin.dx, -origin.dy);
    matrix.scale(scale.dx, scale.dy);

    Offset topLeft = Offset(0, 0);
    Offset topRight = Offset(innerSize.width, 0);
    Offset bottomLeft = Offset(0, innerSize.height);
    Offset bottomRight = Offset(innerSize.width, innerSize.height);

    Offset rotatedTopLeft = transformOffset(topLeft, matrix, origin);
    Offset rotatedTopRight = transformOffset(topRight, matrix, origin);
    Offset rotatedBottomLeft = transformOffset(bottomLeft, matrix, origin);
    Offset rotatedBottomRight = transformOffset(bottomRight, matrix, origin);

    double minX = min(
      min(rotatedTopLeft.dx, rotatedTopRight.dx),
      min(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double maxX = max(
      max(rotatedTopLeft.dx, rotatedTopRight.dx),
      max(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double minY = min(
      min(rotatedTopLeft.dy, rotatedTopRight.dy),
      min(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );
    double maxY = max(
      max(rotatedTopLeft.dy, rotatedTopRight.dy),
      max(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );

    double scaleX = size.width / (maxX - minX);
    double scaleY = size.height / (maxY - minY);

    Matrix4 newMatrix = parentMatrix?.clone() ?? Matrix4.identity();

    origin = alignment.alongSize(size);

    newMatrix.translate(origin.dx, origin.dy);
    newMatrix.scale(scaleX, scaleY);
    newMatrix.rotateZ(rotation);
    newMatrix.translate(-origin.dx, -origin.dy);
    newMatrix.scale(scale.dx, scale.dy);

    return newMatrix;
  }

  Matrix4 computeBoundingBoxMatrix(Size size) {
    Matrix4 matrix = Matrix4.identity();
    var scale = this.scale ?? const Offset(1, 1);
    matrix.scale(scale.dx, scale.dy);
    return matrix;
  }

  CanvasLayoutData drag(Offset delta) => this;

  CanvasLayoutData rotate(double delta) => this;

  CanvasLayoutData resizeUp(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeDown(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeLeft(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeRight(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeUpLeft(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeUpRight(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeDownLeft(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData resizeDownRight(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleUp(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleDown(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleLeft(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleRight(double delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleUpLeft(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleUpRight(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleDownLeft(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;

  CanvasLayoutData rescaleDownRight(Offset delta,
          {bool symmetric = false, bool preserveAspectRatio = false}) =>
      this;
}

class AbsoluteLayoutData extends CanvasLayoutData {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;

  const AbsoluteLayoutData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width,
    this.height,
    super.textDirection,
    super.rotation,
    super.scale,
  });

  AbsoluteLayoutData copyWith({
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    double? height,
    double? rotation,
    Offset? scale,
  }) {
    return AbsoluteLayoutData(
      top: top ?? this.top,
      left: left ?? this.left,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }

  @override
  CanvasLayoutData drag(Offset delta) {
    return copyWith(
      top: top == null ? null : top! + delta.dy,
      left: left == null ? null : left! + delta.dx,
      right: right == null ? null : right! - delta.dx,
      bottom: bottom == null ? null : bottom! - delta.dy,
    );
  }

  double computeWidth(double parentWidth) {
    if (width != null) {
      return width!;
    }
    if (left != null && right != null) {
      return parentWidth - left! - right!;
    }
    return 0;
  }

  double computeHeight(double parentHeight) {
    if (height != null) {
      return height!;
    }
    if (top != null && bottom != null) {
      return parentHeight - top! - bottom!;
    }
    return 0;
  }

  @override
  String toString() {
    return 'AbsoluteLayoutData{top: $top, left: $left, right: $right, bottom: $bottom, width: $width, height: $height}';
  }
}

class FixedLayoutData extends CanvasLayoutData {
  final SizeConstraint width;
  final SizeConstraint height;

  const FixedLayoutData({
    this.width = const FixedSizeConstraint(0),
    this.height = const FixedSizeConstraint(0),
    super.textDirection,
    super.rotation,
    super.scale,
  });
}

class FlexLayoutData extends CanvasLayoutData {
  final double flex;
  final double min;
  final double max;
  final SizeConstraint cross;

  const FlexLayoutData({
    this.flex = 1,
    this.min = 0,
    this.max = double.infinity,
    this.cross = const IntrinsicSizeConstraint(),
    super.textDirection,
    super.rotation,
    super.scale,
  });
}
