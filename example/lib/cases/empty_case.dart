import 'package:canvas/canvas.dart';
import 'package:example/app.dart';

class EmptyCase extends TestCase {
  @override
  String get name => 'Empty Test Case';

  @override
  String get description => 'A test case with no content.';

  @override
  CanvasRoot createRoot() {
    final canvasRoot = CanvasRoot();
    canvasRoot.addChild(
      EditableCanvasObject(
        debugLabel: 'Empty Object',
        layoutData: const AbsoluteLayoutData(
          width: 100,
          height: 100,
        ),
      ),
    );
    return canvasRoot;
  }
}
