import 'dart:math';

import 'package:flutter/widgets.dart';

import '../canvas.dart';

const List<double> _rotationSnap = [
  0,
  45,
  90,
  135,
  180,
  225,
  270,
  315,
];

double snapRotation(double angle, {double threshold = 10}) {
  // convert to degrees, and limit to 0-360
  var degree = (angle * 180 / pi) % 360;
  // find the closest snap point
  for (final snap in _rotationSnap) {
    if ((degree - snap).abs() < threshold) {
      // return the snap point in radians
      return snap * pi / 180;
    }
  }
  // no snap point found, return the original angle
  return angle;
}

// CanvasHitTestResult hitTestGizmo(
//     CanvasItemPointer item,
//     Offset pointer,
//     CanvasItemTransform transform,
//     CanvasTransform canvasTransform,
//     StandardTransformControlThemeData theme,
//     {bool testGizmoHandles = true,
//     CanvasHitTestResult? parent}) {
//   final parentResult = _hitTestGizmo(
//     item,
//     pointer,
//     transform,
//     canvasTransform,
//     theme,
//     testGizmoHandles: false,
//     parent: parent,
//   );
//   for (int i = 0; i < item.item.length; i++) {
//     var canvasItemTarget = CanvasItemPointer(item.item, i);
//     final childTransform = transform.applyToChild(canvasItemTarget);
//     final childResult = hitTestGizmo(
//       canvasItemTarget,
//       pointer,
//       childTransform,
//       canvasTransform,
//       theme,
//       testGizmoHandles: false,
//       parent: parentResult,
//     );
//     if (childResult.type != CanvasHitTestType.none) {
//       return childResult;
//     }
//   }
//   return parentResult;
// }

// CanvasHitTestResult _hitTestGizmo(
//     CanvasItemPointer item,
//     Offset pointer,
//     CanvasItemTransform transform,
//     CanvasTransform canvasTransform,
//     StandardTransformControlThemeData theme,
//     {bool testGizmoHandles = true,
//     CanvasHitTestResult? parent}) {
//   pointer = transformHitPoint(pointer, canvasTransform, transform);
//
//   final bounds = Offset.zero & transform.size;
//
//   if (!testGizmoHandles) {
//     if (bounds.contains(pointer)) {
//       return CanvasHitTestResult(
//           type: CanvasHitTestType.selection,
//           position: pointer,
//           item: item,
//           parent: parent);
//     }
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.none, position: pointer, item: item);
//   }
//
//   final topLeftRect = Rect.fromCenter(
//     center: bounds.topLeft,
//     width: theme.macroSize.width / canvasTransform.scale,
//     height: theme.macroSize.height / canvasTransform.scale,
//   ).inflate(theme.macroBorderWidth / canvasTransform.scale);
//   if (topLeftRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.topLeft,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final topRightRect = Rect.fromCenter(
//     center: bounds.topRight,
//     width: theme.macroSize.width / canvasTransform.scale,
//     height: theme.macroSize.height / canvasTransform.scale,
//   ).inflate(theme.macroBorderWidth / canvasTransform.scale);
//   if (topRightRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.topRight,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final bottomLeftRect = Rect.fromCenter(
//     center: bounds.bottomLeft,
//     width: theme.macroSize.width / canvasTransform.scale,
//     height: theme.macroSize.height / canvasTransform.scale,
//   ).inflate(theme.macroBorderWidth / canvasTransform.scale);
//   if (bottomLeftRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.bottomLeft,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final bottomRightRect = Rect.fromCenter(
//     center: bounds.bottomRight,
//     width: theme.macroSize.width / canvasTransform.scale,
//     height: theme.macroSize.height / canvasTransform.scale,
//   ).inflate(theme.macroBorderWidth / canvasTransform.scale);
//   if (bottomRightRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.bottomRight,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final topRect = Rect.fromCenter(
//     center: bounds.topCenter,
//     width: theme.microSize.width / canvasTransform.scale,
//     height: theme.microSize.height / canvasTransform.scale,
//   ).inflate(theme.microBorderWidth / canvasTransform.scale);
//   if (topRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.top,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final bottomRect = Rect.fromCenter(
//     center: bounds.bottomCenter,
//     width: theme.microSize.width / canvasTransform.scale,
//     height: theme.microSize.height / canvasTransform.scale,
//   ).inflate(theme.microBorderWidth / canvasTransform.scale);
//   if (bottomRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.bottom,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final leftRect = Rect.fromCenter(
//     center: bounds.centerLeft,
//     width: theme.microSize.width / canvasTransform.scale,
//     height: theme.microSize.height / canvasTransform.scale,
//   ).inflate(theme.microBorderWidth / canvasTransform.scale);
//   if (leftRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.left,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final rightRect = Rect.fromCenter(
//     center: bounds.centerRight,
//     width: theme.microSize.width / canvasTransform.scale,
//     height: theme.microSize.height / canvasTransform.scale,
//   ).inflate(theme.microBorderWidth / canvasTransform.scale);
//   if (rightRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.right,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   final rotationRect = Rect.fromCenter(
//     center: bounds.topCenter +
//         Offset(0, -theme.rotationLineLength / canvasTransform.scale),
//     width: theme.rotationHandleSize.width / canvasTransform.scale,
//     height: theme.rotationHandleSize.height / canvasTransform.scale,
//   ).inflate(theme.rotationHandleBorderWidth / canvasTransform.scale);
//   if (rotationRect.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.rotation,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//
//   if (bounds.contains(pointer)) {
//     return CanvasHitTestResult(
//         type: CanvasHitTestType.selection,
//         position: pointer,
//         item: item,
//         parent: parent);
//   }
//   return CanvasHitTestResult(
//       type: CanvasHitTestType.none, position: pointer, item: item);
// }

Offset transformHitPoint(Offset point, CanvasTransform canvasTransform,
    CanvasItemTransform transform,
    [bool transformRotation = true, bool fromAnchor = false]) {
  point = point - canvasTransform.offset;
  point = point / canvasTransform.scale;
  point = point - transform.position;
  final anchorOffset = transform.anchorOffset;
  point = point + anchorOffset;
  if (transformRotation) {
    point = rotatePoint(point, anchorOffset, -transform.rotation);
  }
  if (fromAnchor) {
    point = point - anchorOffset;
  }
  return point;
}

class CanvasHitTestResult {
  final CanvasHitTestResult? parent;
  final CanvasHitTestType type;
  final Offset position;
  final CanvasItemPointer itemPointer;

  CanvasHitTestResult({
    this.parent,
    required this.type,
    required this.position,
    required this.itemPointer,
  });

  @override
  String toString() {
    return 'CanvasHitTestResult(type: $type, position: $position)';
  }
}

enum CanvasHitTestType {
  topLeft, // macro
  topRight, // macro
  bottomLeft, // macro
  bottomRight, // macro
  top, // micro
  bottom, // micro
  left, // micro
  right, // micro
  rotation, // rotation handle
  self, // the bounds of the item
  none,
}

Offset rotatePoint(Offset point, Offset center, double angle) {
  final translatedX = point.dx - center.dx;
  final translatedY = point.dy - center.dy;

  final rotatedX = translatedX * cos(angle) - translatedY * sin(angle);
  final rotatedY = translatedX * sin(angle) + translatedY * cos(angle);

  return Offset(rotatedX + center.dx, rotatedY + center.dy);
}

class RectPoint {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  const RectPoint({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  RectPoint.fromRect(Rect rect)
      : topLeft = rect.topLeft,
        topRight = rect.topRight,
        bottomLeft = rect.bottomLeft,
        bottomRight = rect.bottomRight;

  RectPoint translate(Offset offset) {
    return RectPoint(
      topLeft: topLeft + offset,
      topRight: topRight + offset,
      bottomLeft: bottomLeft + offset,
      bottomRight: bottomRight + offset,
    );
  }

  RectPoint scale(double scale) {
    final center = Offset(
      (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) / 4,
      (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) / 4,
    );
    return RectPoint(
      topLeft: center + (topLeft - center) * scale,
      topRight: center + (topRight - center) * scale,
      bottomLeft: center + (bottomLeft - center) * scale,
      bottomRight: center + (bottomRight - center) * scale,
    );
  }

  RectPoint rotate(double angle) {
    final center = Offset(
      (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) / 4,
      (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) / 4,
    );
    return RectPoint(
      topLeft: rotatePoint(topLeft, center, angle),
      topRight: rotatePoint(topRight, center, angle),
      bottomLeft: rotatePoint(bottomLeft, center, angle),
      bottomRight: rotatePoint(bottomRight, center, angle),
    );
  }

  // bool contains(Offset point) {
  //   final ab = topRight - topLeft;
  //   final ap = point - topLeft;
  //   final bc = bottomRight - topRight;
  //   final bp = point - topRight;
  //   final cd = bottomLeft - bottomRight;
  //   final cp = point - bottomRight;
  //   final da = topLeft - bottomLeft;
  //   final dp = point - bottomLeft;
  //   final cross1 = _crossProduct(ab, ap);
  //   final cross2 = _crossProduct(bc, bp);
  //   final cross3 = _crossProduct(cd, cp);
  //   final cross4 = _crossProduct(da, dp);
  //   return (cross1 >= 0 && cross2 >= 0 && cross3 >= 0 && cross4 >= 0) ||
  //       (cross1 <= 0 && cross2 <= 0 && cross3 <= 0 && cross4 <= 0);
  // }

  Rect computeBounds() {
    final left =
        min(min(topLeft.dx, topRight.dx), min(bottomLeft.dx, bottomRight.dx));
    final right =
        max(max(topLeft.dx, topRight.dx), max(bottomLeft.dx, bottomRight.dx));
    final top =
        min(min(topLeft.dy, topRight.dy), min(bottomLeft.dy, bottomRight.dy));
    final bottom =
        max(max(topLeft.dy, topRight.dy), max(bottomLeft.dy, bottomRight.dy));
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

void handlePaintItem(CanvasItem item, CanvasTransform canvasTransform,
    CanvasItemTransform transform, Canvas canvas) {
  // apply canvas transform
  canvas.save();
  canvas.translate(canvasTransform.offset.dx, canvasTransform.offset.dy);
  canvas.scale(canvasTransform.scale);
  // apply item transform
  canvas.translate(transform.position.dx, transform.position.dy);
  final anchorOffset = transform.anchorOffset;
  canvas.rotate(transform.rotation);
  canvas.translate(-anchorOffset.dx, -anchorOffset.dy);
  // paint item
  item.paint(canvas);
  if (kDebugPaintPaintBounds) {
    // paint a dot in the anchor position
    final anchorPaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    canvas.drawCircle(anchorOffset, 2, anchorPaint);
  }
  // restore canvas transform
  canvas.restore();
  if (kDebugPaintPaintBounds) {
    final paintBounds = transform.computePaintBounds();
    final paint = Paint()
      ..color = const Color(0xFF0000FF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(paintBounds, paint);
  }
}

void handlePaintTransformControl(
    TransformControlHandler handler,
    CanvasTransform canvasTransform,
    CanvasItemTransform transform,
    Canvas canvas) {
  // apply canvas transform
  canvas.save();
  canvas.translate(canvasTransform.offset.dx, canvasTransform.offset.dy);
  canvas.scale(canvasTransform.scale);
  // apply item transform
  canvas.translate(transform.position.dx, transform.position.dy);
  final anchorOffset = transform.anchorOffset;
  canvas.rotate(transform.rotation);
  canvas.translate(-anchorOffset.dx, -anchorOffset.dy);
  // paint transform control
  handler.paint(canvas, canvasTransform, transform);
  // restore canvas transform
  canvas.restore();
}

mixin NoChangeMixin on Listenable {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class CanvasItemNode {
  final CanvasItemNode? parent;
  final CanvasItem item;

  CanvasItemNode(this.item, {this.parent});
}
