import 'dart:math';
import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:example/app.dart';

class EmptyCase extends TestCase {
  @override
  String get name => 'Empty Test Case';

  @override
  String get description => 'A test case with no content.';

  @override
  CanvasEditor openEditor() {
    final root = CanvasFrame(children: [
      CanvasFrame(
          debugLabel: 'Empty Frame',
          layoutData: AbsoluteLayoutData(
            width: SizeConstraint.fixed(200),
            height: SizeConstraint.fixed(200),
            top: Position.absolute(0),
            left: Position.absolute(0),
          )),
      CanvasFrame(
          debugLabel: 'Empty Frame 2',
          layoutData: AbsoluteLayoutData(
            width: SizeConstraint.fixed(200),
            height: SizeConstraint.fixed(200),
            top: Position.absolute(400),
            left: Position.absolute(300),
          ).rotateBy(45 * pi / 180)),
    ]);
    return CanvasEditor(root: root);
  }
}
