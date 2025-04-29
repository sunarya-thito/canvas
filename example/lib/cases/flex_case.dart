import 'package:canvas/canvas.dart';
import 'package:example/app.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FlexTestCase extends TestCase {
  @override
  String get name => 'Flex Test Case';

  @override
  String get description => 'A test case for flex layout.';

  CanvasRoot createRoot() {
    final canvasRoot = CanvasRoot();
    canvasRoot.addChild(
      EditableCanvasObject(
        debugLabel: 'Main Object',
        layout: const FlexLayout(
          padding: EdgeInsets.all(60),
          spacing: 20,
        ),
        layoutData: const AbsoluteLayoutData(
          width: 1400,
          height: 600,
        ),
        children: [
          EditableCanvasObject(
            debugLabel: 'Child 1',
            layoutData: const FixedLayoutData(
              width: SizeConstraint.fixed(250),
              height: SizeConstraint.unconstrained(),
            ),
          ),
          EditableCanvasObject(
            debugLabel: 'Child 2',
            layoutData: const FlexLayoutData(
              flex: 2,
              cross: SizeConstraint.unconstrained(),
            ),
          ),
          EditableCanvasObject(
            debugLabel: 'Child 3',
            layoutData: const FlexLayoutData(
              flex: 1,
              cross: SizeConstraint.fixed(300),
            ),
          ),
          EditableCanvasObject(
            debugLabel: 'Child 4',
            layoutData: const FixedLayoutData(
              width: SizeConstraint.fixed(200),
              height: SizeConstraint.fixed(200),
            ),
          ),
          EditableCanvasObject(
            debugLabel: 'Abs Child 1',
            layoutData: const AbsoluteLayoutData(
              top: 20,
              left: 20,
              width: 100,
              height: 100,
            ),
          ),
          EditableCanvasObject(
            debugLabel: 'Abs Child 2',
            layoutData: const AbsoluteLayoutData(
              bottom: 20,
              right: 20,
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
    );
    return canvasRoot;
  }
}
