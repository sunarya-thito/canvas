import 'package:canvas/canvas.dart';
import 'package:example/app.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FlexTestCase extends TestCase {
  @override
  String get name => 'Flex Test Case';

  @override
  String get description => 'A test case for flex layout.';

  @override
  CanvasEditor openEditor() {
    return CanvasEditor(
      root: CanvasFrame(
        children: [
          CanvasFrame(
              debugLabel: 'Main Frame',
              layoutData: AbsoluteLayoutData(
                width: SizeConstraint.fixed(1400),
                height: SizeConstraint.fixed(600),
                top: Position.absolute(0),
                left: Position.absolute(0),
              ),
              layout: const FlexLayout(
                padding: EdgeInsets.all(20),
                spacing: 20,
              ),
              children: [
                CanvasFrame(
                  debugLabel: 'Child 1',
                  layoutData: FlexibleLayoutData(
                    width: SizeConstraint.fixed(250),
                    height: SizeConstraint.unconstrained,
                  ),
                ),
                CanvasFrame(
                  debugLabel: 'Child 2',
                  layoutData: FlexibleLayoutData(
                    width: SizeConstraint.flex(2),
                    height: SizeConstraint.unconstrained,
                  ),
                ),
                CanvasFrame(
                  debugLabel: 'Child 3',
                  layoutData: FlexibleLayoutData(
                    width: SizeConstraint.flex(1),
                    height: SizeConstraint.fixed(300),
                  ),
                ),
                CanvasFrame(
                  debugLabel: 'Child 4',
                  layoutData: FlexibleLayoutData(
                    width: SizeConstraint.fixed(200),
                    height: SizeConstraint.fixed(200),
                  ),
                ),
                CanvasFrame(
                  debugLabel: 'Abs Child 1',
                  layoutData: AbsoluteLayoutData(
                    top: Position.absolute(20),
                    left: Position.absolute(20),
                    width: SizeConstraint.fixed(100),
                    height: SizeConstraint.fixed(100),
                  ),
                ),
                CanvasFrame(
                  debugLabel: 'Abs Child 2',
                  layoutData: AbsoluteLayoutData(
                    bottom: Position.absolute(20),
                    right: Position.absolute(20),
                    width: SizeConstraint.fixed(100),
                    height: SizeConstraint.fixed(100),
                  ),
                ),
              ])
        ],
      ),
    );
  }
}
