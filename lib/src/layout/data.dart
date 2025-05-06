import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/layout/constraint.dart';
import 'package:canvas/src/layout/position.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

abstract class CanvasLayoutData {
  final Offset? shear;
  final Offset? scale;
  final BoxConstraints? constraints;

  const CanvasLayoutData({
    this.shear,
    this.scale,
    this.constraints,
  });

  CanvasLayoutData copyWith({
    Offset? shear,
    Offset? scale,
    BoxConstraints? constraints,
  });

  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget) {
    return this;
  }

  Matrix4 get transform {
    Matrix4 matrix = Matrix4.identity();
    if (shear != null) {
      matrix = matrix * computeShearMatrix(shear!);
    }
    if (scale != null) {
      matrix = matrix * Matrix4.diagonal3Values(scale!.dx, scale!.dy, 1);
    }
    return matrix;
  }
}

class AbsoluteLayoutData extends CanvasLayoutData {
  final Position? top;
  final Position? left;
  final Position? right;
  final Position? bottom;
  final ConstrainedSizeConstraint? width;
  final ConstrainedSizeConstraint? height;
  final bool scaleHorizontal;
  final bool scaleVertical;

  const AbsoluteLayoutData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width,
    this.height,
    super.shear,
    super.scale,
    super.constraints,
    this.scaleHorizontal = false,
    this.scaleVertical = false,
  });

  @override
  CanvasLayoutData copyWith({
    Offset? shear,
    Offset? scale,
    BoxConstraints? constraints,
  }) {
    return AbsoluteLayoutData(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      scaleHorizontal: scaleHorizontal,
      scaleVertical: scaleVertical,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
      constraints: constraints ?? this.constraints,
    );
  }
}

class FlexibleLayoutData extends CanvasLayoutData {
  final ConstrainedSizeConstraint width;
  final ConstrainedSizeConstraint height;

  const FlexibleLayoutData({
    this.width = const FixedSizeConstraint(0),
    this.height = const FixedSizeConstraint(0),
    super.shear,
    super.scale,
    super.constraints,
  });

  @override
  CanvasLayoutData copyWith({
    Offset? shear,
    Offset? scale,
    BoxConstraints? constraints,
  }) {
    return FlexibleLayoutData(
      width: width,
      height: height,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
      constraints: constraints ?? this.constraints,
    );
  }
}

class PathLayoutData extends CanvasLayoutData {
  final double index;
  final bool rotateAlongPath;
  final Offset offset;
  final Alignment alignment;

  const PathLayoutData({
    required this.index,
    required this.rotateAlongPath,
    required this.offset,
    required this.alignment,
    super.shear,
    super.scale,
    super.constraints,
  });

  @override
  CanvasLayoutData copyWith({
    Offset? shear,
    Offset? scale,
    BoxConstraints? constraints,
    double? index,
    bool? rotateAlongPath,
    Offset? offset,
    Alignment? alignment,
  }) {
    return PathLayoutData(
      index: index ?? this.index,
      rotateAlongPath: rotateAlongPath ?? this.rotateAlongPath,
      offset: offset ?? this.offset,
      alignment: alignment ?? this.alignment,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
      constraints: constraints ?? this.constraints,
    );
  }
}
