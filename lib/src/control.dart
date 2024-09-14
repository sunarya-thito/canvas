import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';

abstract class TransformControl {
  const TransformControl();
  TransformControlHandler createHandler();
}

abstract class TransformControlHandler implements Listenable {
  void onPointerMove(Offset position);
  void paint(Canvas canvas, CanvasTransform canvasTransform,
      CanvasItemTransform transform);
  CanvasHitTestType? hitTest(Offset position, CanvasTransform canvasTransform,
      CanvasItemTransform transform);
  void dispose();
  Rect computePaintBounds(
      CanvasTransform canvasTransform, CanvasItemTransform transform);
}

class StandardTransformControlThemeData {
  final Color macroColor;
  final Color macroBorderColor;
  final Color microColor;
  final Color microBorderColor;
  final Size macroSize;
  final Size microSize;
  final double macroBorderWidth;
  final double microBorderWidth;
  final Color selectionBorderColor;
  final double selectionBorderWidth;
  final Color rotationLineColor;
  final double rotationLineWidth;
  final double rotationLineLength;
  final Color rotationHandleColor;
  final Size rotationHandleSize;
  final double rotationHandleBorderWidth;
  final Color rotationHandleBorderColor;

  const StandardTransformControlThemeData({
    this.macroColor = const Color(0xFFFFFFFF),
    this.macroBorderColor = const Color(0xFF000000),
    this.microColor = const Color(0xFFFFFFFF),
    this.microBorderColor = const Color(0xFF000000),
    this.macroSize = const Size(10, 10),
    this.microSize = const Size(8, 8),
    this.macroBorderWidth = 1,
    this.microBorderWidth = 1,
    this.selectionBorderColor = const Color(0xFF000000),
    this.selectionBorderWidth = 1,
    this.rotationLineColor = const Color(0xFF000000),
    this.rotationLineWidth = 1,
    this.rotationHandleColor = const Color(0xFFFFFFFF),
    this.rotationHandleSize = const Size(10, 10),
    this.rotationHandleBorderWidth = 1,
    this.rotationHandleBorderColor = const Color(0xFF000000),
    this.rotationLineLength = 25,
  });
}

class StandardTransformControl extends TransformControl {
  final StandardTransformControlThemeData theme;

  const StandardTransformControl({required this.theme});

  @override
  TransformControlHandler createHandler() {
    return _StandardTransformControlHandler(theme);
  }
}

class _StandardTransformControlHandler extends TransformControlHandler
    with NoChangeMixin {
  final StandardTransformControlThemeData theme;

  _StandardTransformControlHandler(this.theme);

  @override
  void onPointerMove(Offset position) {}

  @override
  void dispose() {}

  @override
  CanvasHitTestType? hitTest(Offset position, CanvasTransform canvasTransform,
      CanvasItemTransform transform) {
    final rect = Offset.zero & transform.size;

    final topLeftRect = Rect.fromCenter(
      center: rect.topLeft,
      width: theme.macroSize.width,
      height: theme.macroSize.height,
    );
    if (topLeftRect.contains(position)) {
      return CanvasHitTestType.topLeft;
    }

    final topRightRect = Rect.fromCenter(
      center: rect.topRight,
      width: theme.macroSize.width,
      height: theme.macroSize.height,
    );
    if (topRightRect.contains(position)) {
      return CanvasHitTestType.topRight;
    }

    final bottomLeftRect = Rect.fromCenter(
      center: rect.bottomLeft,
      width: theme.macroSize.width,
      height: theme.macroSize.height,
    );
    if (bottomLeftRect.contains(position)) {
      return CanvasHitTestType.bottomLeft;
    }

    final bottomRightRect = Rect.fromCenter(
      center: rect.bottomRight,
      width: theme.macroSize.width,
      height: theme.macroSize.height,
    );
    if (bottomRightRect.contains(position)) {
      return CanvasHitTestType.bottomRight;
    }

    final topCenterRect = Rect.fromCenter(
      center: rect.topCenter,
      width: theme.microSize.width,
      height: theme.microSize.height,
    );
    if (topCenterRect.contains(position)) {
      return CanvasHitTestType.top;
    }

    final bottomCenterRect = Rect.fromCenter(
      center: rect.bottomCenter,
      width: theme.microSize.width,
      height: theme.microSize.height,
    );
    if (bottomCenterRect.contains(position)) {
      return CanvasHitTestType.bottom;
    }

    final leftCenterRect = Rect.fromCenter(
      center: rect.centerLeft,
      width: theme.microSize.width,
      height: theme.microSize.height,
    );
    if (leftCenterRect.contains(position)) {
      return CanvasHitTestType.left;
    }

    final rightCenterRect = Rect.fromCenter(
      center: rect.centerRight,
      width: theme.microSize.width,
      height: theme.microSize.height,
    );
    if (rightCenterRect.contains(position)) {
      return CanvasHitTestType.right;
    }

    final rotationHandleRect = Rect.fromCenter(
      center: rect.topCenter,
      width: theme.rotationHandleSize.width,
      height: theme.rotationHandleSize.height,
    );
    if (rotationHandleRect.contains(position)) {
      return CanvasHitTestType.rotation;
    }

    return null;
  }

  @override
  void paint(Canvas canvas, CanvasTransform canvasTransform,
      CanvasItemTransform transform) {
    // draw the selection border
    final paint = Paint()
      ..color = theme.selectionBorderColor
      ..strokeWidth = theme.selectionBorderWidth / canvasTransform.scale
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & transform.size;
    canvas.drawRect(rect, paint);

    // rotation line
    final rotationLinePaint = Paint()
      ..color = theme.rotationLineColor
      ..strokeWidth = theme.rotationLineWidth / canvasTransform.scale;
    final rotationLineStart = rect.topCenter;
    final rotationLineEnd = rotationLineStart +
        Offset(0, -theme.rotationLineLength / canvasTransform.scale);
    canvas.drawLine(rotationLineStart, rotationLineEnd, rotationLinePaint);

    // draw the control handles
    final macroPaint = Paint()
      ..color = theme.macroColor
      ..style = PaintingStyle.fill;
    final macroBorderPaint = Paint()
      ..color = theme.macroBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.macroBorderWidth / canvasTransform.scale;
    final microPaint = Paint()
      ..color = theme.microColor
      ..style = PaintingStyle.fill;
    final microBorderPaint = Paint()
      ..color = theme.microBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.microBorderWidth / canvasTransform.scale;
    final rotationHandlePaint = Paint()
      ..color = theme.rotationHandleColor
      ..style = PaintingStyle.fill;
    final rotationHandleBorderPaint = Paint()
      ..color = theme.rotationHandleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.rotationHandleBorderWidth / canvasTransform.scale;

    final macroSize = theme.macroSize / canvasTransform.scale;
    final microSize = theme.microSize / canvasTransform.scale;
    final rotationHandleSize = theme.rotationHandleSize / canvasTransform.scale;

    // top left
    final topLeftRect = Rect.fromCenter(
      center: rect.topLeft,
      width: macroSize.width,
      height: macroSize.height,
    );
    canvas.drawRect(topLeftRect, macroPaint);
    canvas.drawRect(topLeftRect, macroBorderPaint);

    // top right
    final topRightRect = Rect.fromCenter(
      center: rect.topRight,
      width: macroSize.width,
      height: macroSize.height,
    );
    canvas.drawRect(topRightRect, macroPaint);
    canvas.drawRect(topRightRect, macroBorderPaint);

    // bottom left
    final bottomLeftRect = Rect.fromCenter(
      center: rect.bottomLeft,
      width: macroSize.width,
      height: macroSize.height,
    );
    canvas.drawRect(bottomLeftRect, macroPaint);
    canvas.drawRect(bottomLeftRect, macroBorderPaint);

    // bottom right
    final bottomRightRect = Rect.fromCenter(
      center: rect.bottomRight,
      width: macroSize.width,
      height: macroSize.height,
    );
    canvas.drawRect(bottomRightRect, macroPaint);
    canvas.drawRect(bottomRightRect, macroBorderPaint);

    // top center
    final topCenterRect = Rect.fromCenter(
      center: rect.topCenter,
      width: microSize.width,
      height: microSize.height,
    );
    canvas.drawRect(topCenterRect, microPaint);
    canvas.drawRect(topCenterRect, microBorderPaint);

    // bottom center
    final bottomCenterRect = Rect.fromCenter(
      center: rect.bottomCenter,
      width: microSize.width,
      height: microSize.height,
    );
    canvas.drawRect(bottomCenterRect, microPaint);
    canvas.drawRect(bottomCenterRect, microBorderPaint);

    // left center
    final leftCenterRect = Rect.fromCenter(
      center: rect.centerLeft,
      width: microSize.width,
      height: microSize.height,
    );
    canvas.drawRect(leftCenterRect, microPaint);
    canvas.drawRect(leftCenterRect, microBorderPaint);

    // right center
    final rightCenterRect = Rect.fromCenter(
      center: rect.centerRight,
      width: microSize.width,
      height: microSize.height,
    );
    canvas.drawRect(rightCenterRect, microPaint);
    canvas.drawRect(rightCenterRect, microBorderPaint);

    // draw the rotation handle
    final rotationHandleRect = Rect.fromCenter(
      center: rotationLineEnd,
      width: rotationHandleSize.width,
      height: rotationHandleSize.height,
    );
    canvas.drawOval(rotationHandleRect, rotationHandlePaint);
    canvas.drawOval(rotationHandleRect, rotationHandleBorderPaint);
  }

  @override
  Rect computePaintBounds(
      CanvasTransform canvasTransform, CanvasItemTransform transform) {
    final rect = Offset.zero & transform.size;
    final macroSize = theme.macroSize / canvasTransform.scale;
    final microSize = theme.microSize / canvasTransform.scale;
    final rotationHandleSize = theme.rotationHandleSize / canvasTransform.scale;
    final rotationLineLength = theme.rotationLineLength / canvasTransform.scale;

    final topLeftRect = Rect.fromCenter(
      center: rect.topLeft,
      width: macroSize.width,
      height: macroSize.height,
    );
    final topRightRect = Rect.fromCenter(
      center: rect.topRight,
      width: macroSize.width,
      height: macroSize.height,
    );
    final bottomLeftRect = Rect.fromCenter(
      center: rect.bottomLeft,
      width: macroSize.width,
      height: macroSize.height,
    );
    final bottomRightRect = Rect.fromCenter(
      center: rect.bottomRight,
      width: macroSize.width,
      height: macroSize.height,
    );
    final topCenterRect = Rect.fromCenter(
      center: rect.topCenter,
      width: microSize.width,
      height: microSize.height,
    );
    final bottomCenterRect = Rect.fromCenter(
      center: rect.bottomCenter,
      width: microSize.width,
      height: microSize.height,
    );
    final leftCenterRect = Rect.fromCenter(
      center: rect.centerLeft,
      width: microSize.width,
      height: microSize.height,
    );
    final rightCenterRect = Rect.fromCenter(
      center: rect.centerRight,
      width: microSize.width,
      height: microSize.height,
    );
    final rotationHandleRect = Rect.fromCenter(
      center: rect.topCenter + Offset(0, -rotationLineLength),
      width: rotationHandleSize.width,
      height: rotationHandleSize.height,
    );

    return topLeftRect
        .expandToInclude(topRightRect)
        .expandToInclude(bottomLeftRect)
        .expandToInclude(bottomRightRect)
        .expandToInclude(topCenterRect)
        .expandToInclude(bottomCenterRect)
        .expandToInclude(leftCenterRect)
        .expandToInclude(rightCenterRect)
        .expandToInclude(rotationHandleRect);
  }
}
