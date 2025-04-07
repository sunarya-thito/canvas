import 'package:canvas/canvas.dart';
import 'package:example/app.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FlexTestCase extends TestCase {
  @override
  String get name => 'Flex Test Case';

  @override
  String get description => 'A test case for flex layout.';

  @override
  final CanvasRoot root = CanvasRoot();

  late CanvasObject mainObject;

  FlexTestCase() {
    root.addChild(
      mainObject = EditableCanvasObject(
        debugLabel: 'Main Object',
        layout: const FlexLayout(
          padding: EdgeInsets.all(60),
          spacing: 20,
        ),
        layoutData: const AbsoluteLayoutData(
          width: 1200,
          height: 600,
        ),
        children: [
          EditableCanvasObject(
            debugLabel: 'Child 1',
            layoutData: const FlexLayoutData(
              flex: 1,
              cross: SizeConstraint.unconstrained(),
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
              cross: SizeConstraint.unconstrained(),
            ),
          ),
        ],
      ),
    );
  }
}
