import 'package:canvas/canvas.dart';
import 'package:example/app.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FlexTestCase extends TestCase {
  @override
  String get name => 'Flex Test Case';

  @override
  String get description => 'A test case for flex layout.';

  @override
  CanvasRoot root = CanvasRoot();

  late CanvasObject mainObject;

  FlexTestCase() {
    root.addChild(
      mainObject = CanvasObject(
        debugLabel: 'Main Object',
        children: [
          CanvasObject(
            debugLabel: 'Child 1',
            layoutData: const FlexLayoutData(
              flex: 1,
              cross: SizeConstraint.unconstrained(),
            ),
          ),
          CanvasObject(
            debugLabel: 'Child 2',
            layoutData: const FlexLayoutData(
              flex: 2,
              cross: SizeConstraint.unconstrained(),
            ),
          ),
          CanvasObject(
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

  @override
  void update() {
    mainObject.layout = FlexLayout(
      direction: direction.value,
      mainAxisAlignment: mainAlignment.value,
      crossAxisAlignment: crossAlignment.value,
      padding: EdgeInsets.only(
        top: topPadding.value,
        left: leftPadding.value,
        right: rightPadding.value,
        bottom: bottomPadding.value,
      ),
      spacing: spacing.value,
    );
    mainObject.layoutData = AbsoluteLayoutData(
      width: width.value,
      height: height.value,
    );
  }

  final direction = EnumProperty<Axis>(
    name: 'Direction',
    value: Axis.horizontal,
    values: Axis.values,
  );

  final mainAlignment = EnumProperty<FlexAlignment>(
    name: 'Main Alignment',
    value: FlexAlignment.start,
    values: FlexAlignment.values,
  );

  final crossAlignment = EnumProperty<FlexAlignment>(
    name: 'Cross Alignment',
    value: FlexAlignment.start,
    values: FlexAlignment.values,
  );

  final topPadding = NumberProperty(
    name: 'Top Padding',
    value: 0,
  );

  final leftPadding = NumberProperty(
    name: 'Left Padding',
    value: 0,
  );

  final rightPadding = NumberProperty(
    name: 'Right Padding',
    value: 0,
  );

  final bottomPadding = NumberProperty(
    name: 'Bottom Padding',
    value: 0,
  );

  final spacing = NumberProperty(
    name: 'Spacing',
    value: 0,
  );

  final width = NumberProperty(
    name: 'Width',
    value: 1200,
  );

  final height = NumberProperty(
    name: 'Height',
    value: 600,
  );

  @override
  List<TestProperty> get properties => [
        direction,
        mainAlignment,
        crossAlignment,
        topPadding,
        leftPadding,
        rightPadding,
        bottomPadding,
        spacing,
        width,
        height,
      ];
}
