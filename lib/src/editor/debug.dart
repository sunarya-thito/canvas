import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:flutter/widgets.dart';

class _DebugSnappingLine {
  final SnapAnchor point;
  final SnappingLine line;

  const _DebugSnappingLine({
    required this.point,
    required this.line,
  });
}

class SnapAnchorRenderer extends StatelessWidget {
  final CanvasEditorHandler editor;
  final Matrix4 parentTransform;

  const SnapAnchorRenderer({
    super.key,
    required this.editor,
    required this.parentTransform,
  });

  @override
  Widget build(BuildContext context) {
    List<_DebugSnappingLine> snappingLines = [];
    editor.visitSnapAnchor(
      (point) {
        point.visitLines(
          (line) {
            snappingLines.add(_DebugSnappingLine(
              point: point,
              line: line,
            ));
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
  final List<_DebugSnappingLine> lines;

  const _SnappingLinesPainter({
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = Color.fromARGB(123, 0, 0, 255)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      var point = line.line.offset;
      var direction = line.line.direction;
      // const lineLength = 1000000.0;
      // var startPoint = Offset(
      //   point.dx - lineLength * cos(angle),
      //   point.dy - lineLength * sin(angle),
      // );
      // var endPoint = Offset(
      //   point.dx + lineLength * cos(angle),
      //   point.dy + lineLength * sin(angle),
      // );
      // canvas.drawLine(startPoint, endPoint, paint);
      // canvas.drawCircle(
      //     point, 5, paint..color = Color.fromARGB(255, 0, 0, 255));
      // var startPoint = Offset
      // String? debugOwner = line.point.debugOwner;
      // if (debugOwner != null) {
      //   var textPainter = TextPainter(
      //     text: TextSpan(
      //       text: debugOwner,
      //       style: const TextStyle(
      //         color: Color.fromARGB(255, 0, 0, 255),
      //         fontSize: 12,
      //         fontWeight: FontWeight.w400,
      //       ),
      //     ),
      //     textDirection: TextDirection.ltr,
      //   );
      //   textPainter.layout();
      //   var textOffset = Offset(
      //     point.dx + 8,
      //     point.dy - textPainter.height / 2,
      //   );
      //   textPainter.paint(canvas, textOffset);
      //   textPainter.dispose();
      // }
    }
  }

  @override
  bool shouldRepaint(covariant _SnappingLinesPainter oldDelegate) {
    return oldDelegate.lines != lines;
  }
}

class RandomContainer extends StatelessWidget {
  final int seed;
  final Widget? child;

  const RandomContainer({super.key, required this.seed, this.child});

  Color _randomColor(Random random, {double? value}) {
    HSVColor hsvColor = HSVColor.fromAHSV(
      1.0,
      random.nextDouble() * 360,
      0.5,
      value ?? 0.8,
    );
    return hsvColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    Random random = Random(seed);
    return Container(
      decoration: BoxDecoration(
        color: _randomColor(random),
        border: Border.all(
          color: _randomColor(random, value: 0.4),
          width: 3.0,
        ),
      ),
      child: child,
    );
  }
}
