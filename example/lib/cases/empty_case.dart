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
    final root = CanvasRoot(children: [
      CanvasFrame(
          debugLabel: 'Empty Frame',
          layoutData: const ParentLayoutData(
            size: Size(100, 100),
          )),
    ]);
    return CanvasEditor(root: root);
  }
}
