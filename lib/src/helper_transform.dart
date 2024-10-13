import 'package:flutter/rendering.dart';

class BoxTransform {
  final Offset position;
  final Matrix4? parentTransform;
  final Matrix4 transform;
  final Size size;

  Offset positionDelta = Offset.zero;
  Size sizeDelta = Size.zero;

  BoxTransform({
    required this.position,
    required this.transform,
    required this.size,
    this.parentTransform,
  });

  Offset transformDelta(Offset delta) {
    if (parentTransform != null) {
      return MatrixUtils.transformPoint(parentTransform!, delta);
    }
    return delta;
  }
}
