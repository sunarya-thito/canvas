import 'package:canvas/canvas.dart';
import 'package:example/app.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(ShadcnApp(
    home: Stack(
      fit: StackFit.passthrough,
      children: [
        const CanvasExampleApp(),
        Positioned(
          top: 50,
          left: 50,
          width: 200,
          height: 200,
          child: IgnorePointer(child: SloppinessTest()),
        ),
      ],
    ),
    theme: ThemeData(
      colorScheme: ColorSchemes.darkGreen(),
      radius: 0.5,
    ),
    enableScrollInterception: false,
  ));
}

class SloppinessTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Path roundedRect = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 200, 200),
        const Radius.circular(20),
      ));
    Path foreground = Sloppiness.artist.retrace(roundedRect, 0);
    return CustomPaint(
      painter:
          PathPainter(path: foreground, color: Colors.white, strokeWidth: 3),
    );
  }
}

class PathPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double strokeWidth;

  const PathPainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintPath(
        path,
        canvas,
        size,
        FrameBorder(
          top: FrameBorderSide(color: Colors.red, width: 2),
          left: FrameBorderSide(color: Colors.green, width: 20),
          right: FrameBorderSide(color: Colors.blue, width: 2),
          bottom: FrameBorderSide(color: Colors.yellow, width: 2),
        ));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
