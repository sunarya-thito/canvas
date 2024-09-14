import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

import '../canvas.dart';

const kDebugPaintPaintBounds = false;

class CanvasPainter extends CustomPainter implements CanvasContainer {
  final List<CanvasItem> items;
  @override
  final CanvasTransform transform;
  final TransformControlHandler transformControlHandler;

  CanvasPainter({
    required this.items,
    required this.transform,
    required this.transformControlHandler,
  });

  @override
  CanvasItem operator [](int index) {
    return items[index];
  }

  @override
  int get length => items.length;

  void paintChild(Canvas canvas, Size size, CanvasItemPointer item,
      CanvasItemTransform itemTransform) {
    final paintBounds = itemTransform.computePaintBounds();
    if (!paintBounds.overlaps(Offset.zero & size)) {
      return;
    }
    // handlePaintItem(
    handlePaintItem(item.item, transform, itemTransform, canvas);
    for (int i = 0; i < item.item.length; i++) {
      final pointer = CanvasItemPointer(item.item, i);
      paintChild(
        canvas,
        size,
        pointer,
        itemTransform.applyToChild(pointer),
      );
    }
  }

  void paintChildGizmo(Canvas canvas, Size size, CanvasItemPointer item,
      CanvasItemTransform itemTransform) {
    if (item.item.selected) {
      final paintBounds = transformControlHandler.computePaintBounds(
          transform, item.item.transform);
      if (!paintBounds.overlaps(Offset.zero & size)) {
        return;
      }
      handlePaintTransformControl(
        transformControlHandler,
        transform,
        itemTransform,
        canvas,
      );
    }
    for (int i = 0; i < item.item.length; i++) {
      final pointer = CanvasItemPointer(item.item, i);
      paintChildGizmo(
        canvas,
        size,
        pointer,
        itemTransform.applyToChild(pointer),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Note: do not use `transform` from CanvasTransform, it is already handled
    // in the `handlePaintItem` and `handlePaintItemGizmo` methods.
    for (int i = 0; i < items.length; i++) {
      final pointer = CanvasItemPointer(this, i);
      paintChild(canvas, size, pointer, pointer.item.transform);
    }
    for (int i = 0; i < items.length; i++) {
      final pointer = CanvasItemPointer(this, i);
      paintChildGizmo(canvas, size, pointer, pointer.item.transform);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true;
  }
}
