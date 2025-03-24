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

    var rotation = this.rotation ?? 0; // (already in radians)

    // based on the rotation, fit the inner size into the outer size
    var cosTheta = cos(rotation);
    var sinTheta = sin(rotation);

    var rotatedWidth = scaledWidth * cosTheta + scaledHeight * sinTheta;
    var rotatedHeight = scaledWidth * sinTheta + scaledHeight * cosTheta;

    return Size(rotatedWidth, rotatedHeight);
  }

  Matrix4 computeMatrix(Size size,
      {Alignment alignment = Alignment.center, Matrix4? parentMatrix}) {
    var scale = this.scale ?? const Offset(1, 1);
    var rotation = this.rotation ?? 0;

    Size innerSize = computeInnerSize(size, alignment);
    Offset origin = alignment.alongSize(innerSize);

    Matrix4 newMatrix = parentMatrix?.clone() ?? Matrix4.identity();

    origin = alignment.alongSize(size);

    newMatrix.translate(origin.dx, origin.dy);
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

  CanvasLayoutData resize(double delta,
          {bool symmetric = false,
          bool preserveAspectRatio = false,
          required Alignment alignment}) =>
      this;

  CanvasLayoutData rescale(Offset delta,
          {bool symmetric = false,
          bool preserveAspectRatio = false,
          required Alignment alignment}) =>
      this;

  CanvasLayoutData handleResize(Offset positionDelta, Offset sizeDelta) => this;
  CanvasLayoutData handleRescale(Offset positionDelta, Offset sizeDelta) =>
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
