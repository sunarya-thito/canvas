import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:example/app.dart';

class PerformanceCase extends TestCase {
  @override
  String get name => 'Performance Test Case';

  @override
  String get description => 'A test case to measure performance.';

  @override
  CanvasEditor openEditor() {
    final root = CanvasFrame(children: [
      for (int x = 0; x < 40; x++)
        for (int y = 0; y < 40; y++)
          CanvasFrame(
            debugLabel: 'Frame $x-$y',
            layoutData: AbsoluteLayoutData(
              width: SizeConstraint.fixed(200),
              height: SizeConstraint.fixed(200),
              top: Position.absolute(y * 200.0),
              left: Position.absolute(x * 200.0),
            ),
          ),
    ]);
    return CanvasEditor(root: root);
  }
}
