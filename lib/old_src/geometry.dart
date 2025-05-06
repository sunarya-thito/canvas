import 'dart:math';
import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

const kDeg90 = 90.0 * pi / 180;

class Rotation extends Offset {
  const Rotation(double angle) : super(angle, -angle);
}

Rect normalizeRect(Rect rect) {
  return Offset.zero & rect.size;
}

double rotationFromShear(Offset shear) {
  return (shear.dx - shear.dy) / 2;
}

Offset resizeShear(Size newOuterSize, Offset shear) {
  // anjirlah pusing pala gw cok
  double newWidth = newOuterSize.width;
  double newHeight = newOuterSize.height;
  //    tan(newShearX) =   nW
  //                     ------- * tan(shearX)
  //                       nH
  //    tan(newShearX) =   nH
  //                     ------- * tan(shearY)
  //                       nW
  double tanShearXNew = (newWidth / newHeight) * tan(shear.dx);
  double tanShearYNew = (newHeight / newWidth) * tan(shear.dy);
  //   newShearX = tan-1(tanShearXNew)
  //   newShearY = tan-1(tanShearYNew)
  double newShearX = atan(tanShearXNew); // atan -> tan-1 or arc tangent
  double newShearY = atan(tanShearYNew);
  return Offset(newShearX, newShearY);
}

Offset normalizeOffset(Offset offset) {
  final double length = offset.distance;
  return length > 0 ? offset / length : offset;
}

class FittedSize extends Size {
  final Size boundingBoxSize;

  const FittedSize(this.boundingBoxSize, double width, double height)
      : super(width, height);
}

extension FittedSizeExtension on Size {
  Size get possibleBoundingBoxSize {
    if (this is FittedSize) {
      return (this as FittedSize).boundingBoxSize;
    }
    return this;
  }
}

Size computeFittingSize(Size size, CanvasLayoutData layoutData,
    {required bool fillWidth, required bool fillHeight}) {
  Polygon polygon = Polygon.fromRect(Offset.zero & size);
  Matrix4 transform = layoutData.computeElementTransform(size);
  polygon = polygon.transform(transform);
  Size newSize = polygon.boundingBoxSize;
  double adjustScaleX;
  double adjustScaleY;
  if (fillWidth && fillHeight) {
    adjustScaleX = size.width / newSize.width;
    adjustScaleY = size.height / newSize.height;
  } else if (fillHeight) {
    adjustScaleX = size.width / newSize.width;
    adjustScaleY = adjustScaleX;
  } else if (fillWidth) {
    adjustScaleY = size.height / newSize.height;
    adjustScaleX = adjustScaleY;
  } else {
    return size;
  }
  if (adjustScaleY.isNaN ||
      adjustScaleX.isNaN ||
      (adjustScaleX == 1 && adjustScaleY == 1)) {
    return size;
  }
  print(
      'adjustScaleX: $adjustScaleX, adjustScaleY: $adjustScaleY, fillWidth: $fillWidth, $fillHeight');
  polygon = polygon.scale(Offset(adjustScaleX, adjustScaleY));
  Matrix4 inverted = Matrix4.inverted(transform);
  polygon = polygon.transform(inverted);
  var adjustedSize = polygon.boundingBoxSize;
  return FittedSize(
    size,
    fillWidth ? adjustedSize.width : size.width,
    fillHeight ? adjustedSize.height : size.height,
  );
}

Size computeDirectionalFittingSize(Size size, CanvasLayoutData layoutData,
    {required bool fillMain, required fillCross, required Axis direction}) {
  if (direction == Axis.horizontal) {
    return computeFittingSize(size, layoutData,
        fillWidth: fillMain, fillHeight: fillCross);
  } else {
    return computeFittingSize(size, layoutData,
        fillWidth: fillCross, fillHeight: fillMain);
  }
}

Size computeBoundingBoxFromMatrix(Size size, Matrix4 matrix) {
  Polygon polygon = Polygon.fromRect(Offset.zero & size);
  polygon = polygon.transform(matrix);
  return polygon.boundingBoxSize;
}

Size computeBoundingBox(Size size, CanvasLayoutData layoutData) {
  Polygon polygon = Polygon.fromRect(Offset.zero & size);
  if (layoutData.scale != null) {
    polygon = polygon.scale(layoutData.scale!);
  }
  if (layoutData.shear != null) {
    polygon = polygon.transform(
      computeShearMatrix(layoutData.shear!.dx, layoutData.shear!.dy),
    );
  }
  return polygon.boundingBoxSize;
}

Matrix4 computeShearMatrix(
  double shearX,
  double shearY, {
  Matrix4? parent,
  Alignment? alignment,
  Size? size,
  Offset? origin,
}) {
  final result = Matrix4.identity();

  // Convert alignment into actual Offset origin in the box
  // final Offset originOffset = alignment.alongSize(size);
  if (alignment != null && size != null) {
    final Offset originOffset = alignment.alongSize(size);
    result.translate(originOffset.dx, originOffset.dy);
  } else if (origin != null) {
    result.translate(origin.dx, origin.dy);
  }

  // Apply shear via setEntry
  final shearXMatrix = Matrix4.identity()
    ..setEntry(0, 1, tan(shearX))
    ..setEntry(1, 0, tan(shearY));
  final shearYMatrix = Matrix4.identity()
    ..setEntry(1, 1, cos(shearX))
    ..setEntry(0, 0, cos(shearY));

  // Apply both shears to result
  result.multiply(shearXMatrix);
  result.multiply(shearYMatrix);

  // Translate back
  // result.translate(-originOffset.dx, -originOffset.dy);
  if (alignment != null && size != null) {
    final Offset originOffset = alignment.alongSize(size);
    result.translate(-originOffset.dx, -originOffset.dy);
  } else if (origin != null) {
    result.translate(-origin.dx, -origin.dy);
  }

  // If parent matrix is given, prepend it
  if (parent != null) {
    result.multiply(parent);
  }

  return result;
}

Offset computeShearFromMatrix(Matrix4 matrix) {
  final shearX = atan(matrix.entry(0, 1) / matrix.entry(1, 1));
  final shearY = atan(matrix.entry(1, 0) / matrix.entry(0, 0));
  return Offset(shearX, shearY);
}
