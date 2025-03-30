import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:flutter/widgets.dart';

class SnappingPointRenderer extends StatelessWidget {
  final CanvasEditorHandler editor;
  final Matrix4 parentTransform;

  const SnappingPointRenderer({
    super.key,
    required this.editor,
    required this.parentTransform,
  });

  @override
  Widget build(BuildContext context) {
    List<SnappingLine> snappingLines = [];
    editor.visitSnappingPoint(
      (point) {
        point.visitLines(
          (line) {
            snappingLines.add(line);
            return true;
          },
        );
        return true;
      },
    );
    return Transform(
        transform: parentTransform,
        child: CustomPaint(
          painter: _SnappingLinesPainter(lines: snappingLines),
        ));
  }
}

class _SnappingLinesPainter extends CustomPainter {
  final List<SnappingLine> lines;

  const _SnappingLinesPainter({
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = Color(0xFF0000FF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      var point = line.point;
      var angle = line.angle;
      const lineLength = 1000000.0;
      var startPoint = Offset(
        point.dx - lineLength * cos(angle),
        point.dy - lineLength * sin(angle),
      );
      var endPoint = Offset(
        point.dx + lineLength * cos(angle),
        point.dy + lineLength * sin(angle),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnappingLinesPainter oldDelegate) {
    return oldDelegate.lines != lines;
  }
}
