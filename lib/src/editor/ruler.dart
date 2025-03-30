import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasRulerSnappingPoint {
  final ValueNotifier<double> offset;
  final Axis axis;

  CanvasRulerSnappingPoint({
    required double offset,
    required this.axis,
  }) : offset = ValueNotifier(offset);
}

class CanvasRuler extends StatelessWidget {
  final CanvasEditorController controller;
  final CanvasEditorHandler editor;
  final bool showRuler;
  final Widget child;
  final List<CanvasRulerSnappingPoint> snappingPoints;

  const CanvasRuler({
    super.key,
    required this.controller,
    required this.editor,
    required this.showRuler,
    this.snappingPoints = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CanvasTheme.of(context);
    final width = theme.ruler.rulerWidth;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (!showRuler)
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            bottom: 0,
            child: child,
          ),
        if (showRuler)
          PositionedDirectional(
            top: width,
            start: width,
            end: 0,
            bottom: 0,
            child: child,
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RulerPainter(
                      zoom: controller.value.zoom,
                      offset: controller.value.offset,
                      style: theme.ruler.textStyle,
                      strokeWidth: theme.ruler.strokeWidth,
                      backgroundColor: theme.ruler.backgroundColor,
                      strokeColor: theme.ruler.strokeColor,
                      snappingPoints: snappingPoints,
                      rulerWidth: showRuler ? width : 0,
                      strokeHeight: theme.ruler.strokeHeight,
                      textDirection: Directionality.of(context),
                      snapStrokeColor: theme.snap.strokeColor,
                      snapStrokeWidth: theme.snap.strokeWidth,
                      snapTextStyle: theme.snap.textStyle,
                      pixelGridColor: theme.ruler.pixelGridColor,
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  static const gaps = <double>[
    1,
    5,
    10,
    25,
    50,
    100,
    250,
    1000,
    2500,
    5000,
    10000,
    25000,
    50000,
    100000,
  ];
  final double zoom;
  final Offset offset;
  final TextStyle style;
  final double strokeWidth;
  final double strokeHeight;
  final Color backgroundColor;
  final Color strokeColor;
  final double rulerWidth;
  final TextDirection textDirection;
  final List<CanvasRulerSnappingPoint> snappingPoints;
  final Color snapStrokeColor;
  final double snapStrokeWidth;
  final TextStyle snapTextStyle;
  final Color pixelGridColor;

  _RulerPainter({
    required this.zoom,
    required this.offset,
    required this.style,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.strokeColor,
    required this.snappingPoints,
    required this.rulerWidth,
    required this.textDirection,
    required this.strokeHeight,
    required this.snapStrokeColor,
    required this.snapStrokeWidth,
    required this.snapTextStyle,
    required this.pixelGridColor,
  }) : super(
            repaint: Listenable.merge(snappingPoints.map(
          (e) => e.offset,
        )));

  @override
  void paint(Canvas canvas, Size size) {
    var gap = 100.0;
    // find suitable gap for the current zoom
    int gapIndex;
    for (gapIndex = 0; gapIndex < gaps.length; gapIndex++) {
      if (gaps[gapIndex] * zoom > 50) {
        gap = gaps[gapIndex];
        break;
      }
    }
    Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Size editorSize = Size(size.width - rulerWidth, size.height - rulerWidth);
    Offset rulerOffset =
        Offset(textDirection == TextDirection.ltr ? rulerWidth : 0, rulerWidth);

    if (rulerWidth > 0) {
      // draw the ruler background
      canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, rulerWidth),
        backgroundPaint,
      );
      // vertical (TextDirection adaptive)
      if (textDirection == TextDirection.ltr) {
        canvas.drawRect(
          Rect.fromLTRB(0, 0, rulerWidth, size.height),
          backgroundPaint,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTRB(size.width - rulerWidth, 0, size.width, size.height),
          backgroundPaint,
        );
      }

      // draw the border
      canvas.drawLine(
        Offset(0, rulerWidth),
        Offset(size.width, rulerWidth),
        strokePaint,
      );
      // draw the vertical line
      if (textDirection == TextDirection.ltr) {
        canvas.drawLine(
          Offset(rulerWidth, 0),
          Offset(rulerWidth, size.height),
          strokePaint,
        );
      } else {
        canvas.drawLine(
          Offset(size.width - rulerWidth, 0),
          Offset(size.width - rulerWidth, size.height),
          strokePaint,
        );
      }
      // draw the texts

      double currentHorizontalText =
          ((-offset.dx - editorSize.width / 2 * zoom) / (gap * zoom))
                  .ceilToDouble() -
              1;
      double currentHorizontalTextOffset = rulerOffset.dx +
          (offset.dx + editorSize.width / 2 * zoom) % (gap * zoom) -
          gap * zoom;
      while (currentHorizontalTextOffset < (size.width + gap * zoom)) {
        double opacity = 1;
        // if its near to edge (start or end), go invisible, with the range of gap
        canvas.drawLine(
          Offset(currentHorizontalTextOffset, rulerWidth),
          Offset(currentHorizontalTextOffset, rulerWidth - strokeHeight),
          strokePaint,
        );
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: (currentHorizontalText * gap).toInt().toString(),
            style: style.copyWith(
              color: style.color?.withAlpha((opacity * 255).toInt()),
            ),
          ),
          textDirection: textDirection,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(currentHorizontalTextOffset - textPainter.width / 2,
              rulerWidth - strokeHeight - textPainter.height),
        );
        textPainter.dispose();
        currentHorizontalText++;
        currentHorizontalTextOffset += gap * zoom;
      }

      // draw the vertical texts
      double currentVerticalText =
          ((-offset.dy - editorSize.height / 2 * zoom) / (gap * zoom))
                  .ceilToDouble() -
              1;
      double currentVerticalTextOffset = rulerOffset.dy +
          (offset.dy + editorSize.height / 2 * zoom) % (gap * zoom) -
          gap * zoom;
      while (currentVerticalTextOffset < (size.height + gap * zoom)) {
        double opacity = 1;
        // if its near to edge (start or end), go invisible, with the range of gap
        double startEdge = currentVerticalTextOffset - gap;
        double endEdge = currentVerticalTextOffset + gap;
        if (startEdge < rulerOffset.dy) {
          opacity = (currentVerticalTextOffset / gap).clamp(0, 1);
        } else if (endEdge > size.height - rulerOffset.dy) {
          opacity =
              ((size.height - currentVerticalTextOffset) / gap).clamp(0, 1);
        }
        strokePaint.color = strokeColor.withAlpha((opacity * 255).toInt());
        Offset lineStart = textDirection == TextDirection.ltr
            ? Offset(rulerWidth - strokeHeight, currentVerticalTextOffset)
            : Offset(size.width - rulerWidth, currentVerticalTextOffset);
        canvas.drawLine(
          lineStart,
          Offset(lineStart.dx + strokeHeight, currentVerticalTextOffset),
          strokePaint,
        );
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: (currentVerticalText * gap).toInt().toString(),
            style: style.copyWith(
              color: style.color?.withAlpha((opacity * 255).toInt()),
            ),
          ),
          textDirection: textDirection,
        );
        textPainter.layout();
        // translate to origin
        canvas.save();
        Offset textStart = textDirection == TextDirection.ltr
            ? Offset(rulerWidth - strokeHeight, currentVerticalTextOffset)
            : Offset(size.width - rulerWidth, currentVerticalTextOffset);
        canvas.translate(textStart.dx, textStart.dy);
        canvas.rotate(-pi / 2);
        canvas.translate(-textStart.dx, -textStart.dy);
        // draw the text
        textPainter.paint(
          canvas,
          textStart - Offset(textPainter.width / 2, textPainter.height),
        );
        canvas.restore();
        textPainter.dispose();
        currentVerticalText++;
        currentVerticalTextOffset += gap * zoom;
      }
      // draw a small box at top left
      canvas.drawRect(
        Rect.fromLTRB(0, 0, rulerWidth, rulerWidth),
        backgroundPaint,
      );
    }

// if gapIndex == 0, it means it maxed out the zoom in, and we should show the pixel grid
    if (gapIndex == 0) {
      // vertical grid
      strokePaint.color = pixelGridColor;
      strokePaint.strokeWidth = 1;
      double currentVerticalOffset = rulerOffset.dy +
          (offset.dy + editorSize.height / 2 * zoom) % (gap * zoom);
      while (currentVerticalOffset < size.height) {
        canvas.drawLine(
          Offset(rulerWidth, currentVerticalOffset),
          Offset(size.width, currentVerticalOffset),
          strokePaint,
        );
        currentVerticalOffset += gap * zoom;
      }
      // horizontal grid
      double currentHorizontalOffset = rulerOffset.dx +
          (offset.dx + editorSize.width / 2 * zoom) % (gap * zoom);
      while (currentHorizontalOffset < size.width) {
        canvas.drawLine(
          Offset(currentHorizontalOffset, rulerWidth),
          Offset(currentHorizontalOffset, size.height),
          strokePaint,
        );
        currentHorizontalOffset += gap * zoom;
      }
    }

    if (rulerWidth > 0) {
      strokePaint.color = snapStrokeColor;
      strokePaint.strokeWidth = snapStrokeWidth;
      // draw the snapping points
      for (var snappingPoint in snappingPoints) {
        double snappingPointOffset = snappingPoint.offset.value * zoom;
        if (snappingPoint.axis == Axis.vertical) {
          snappingPointOffset +=
              rulerOffset.dx + offset.dx + editorSize.width / 2 * zoom;
          if (textDirection == TextDirection.ltr &&
              snappingPointOffset < rulerOffset.dy) {
            continue;
          }
          if (textDirection == TextDirection.rtl &&
              snappingPointOffset > size.width - rulerOffset.dy) {
            continue;
          }
          canvas.drawLine(
            Offset(snappingPointOffset, 0),
            Offset(snappingPointOffset, size.height),
            strokePaint,
          );
        } else {
          snappingPointOffset +=
              rulerOffset.dy + offset.dy + editorSize.height / 2 * zoom;
          if (snappingPointOffset < rulerOffset.dy) {
            continue;
          }
          if (snappingPointOffset > size.height) {
            continue;
          }
          canvas.drawLine(
            Offset(0, snappingPointOffset),
            Offset(size.width, snappingPointOffset),
            strokePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.style != style ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.snappingPoints != snappingPoints ||
        oldDelegate.rulerWidth != rulerWidth ||
        oldDelegate.zoom != zoom ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.strokeHeight != strokeHeight ||
        oldDelegate.snapStrokeColor != snapStrokeColor ||
        oldDelegate.snapStrokeWidth != snapStrokeWidth ||
        oldDelegate.snapTextStyle != snapTextStyle;
  }
}
