import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasItemSnapAnchor extends AbsoluteSnapAnchor {
  final CanvasItemState item;

  const CanvasItemSnapAnchor({
    required this.item,
    required super.point,
  });

  @override
  SnapAnchor shift(Offset offset) {
    return CanvasItemSnapAnchor(
      item: item,
      point: point + offset,
    );
  }

  @override
  String? get debugOwner => item.item.debugLabel;

  @override
  String toString() {
    return 'CanvasItemSnapAnchor{item: $item, point: $point}';
  }
}
