import 'package:flutter/widgets.dart';

class TransformControlBox {
  final Size size;
  final Matrix4 transform;

  const TransformControlBox({
    required this.size,
    required this.transform,
  });
}
