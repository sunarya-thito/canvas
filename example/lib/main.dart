import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/scheduler.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(ShadcnApp(
    home: Sample(),
    theme: ThemeData(
      colorScheme: ColorSchemes.darkGreen(),
      radius: 0.5,
    ),
  ));
}

class Sample extends StatefulWidget {
  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> with SingleTickerProviderStateMixin {
  double _elapsed = 0.0;

  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed.inMilliseconds / 1000;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void printChild(CanvasObject child, String name) {
    print('Child $name');
    for (var state in child.activeStates) {
      print('Offset: ${state.parentData.position}');
      print('Size: ${state.size}');
    }
  }

  Offset computeRotationScaleAdjustment(Size outerBox, double rotation) {
    double rad = rotation * (pi / 180); // Convert degrees to radians

    // Compute the bounding box of the rotated inner box
    double cosTheta = cos(rad).abs();
    double sinTheta = sin(rad).abs();

    Offset topLeft = Offset(0, 0);
    Offset topRight = Offset(outerBox.width, 0);
    Offset bottomLeft = Offset(0, outerBox.height);
    Offset bottomRight = Offset(outerBox.width, outerBox.height);

    Offset centerOrigin = Offset(outerBox.width / 2, outerBox.height / 2);
    Offset rotatedTopLeft = rotatePoint(topLeft, rad, centerOrigin);
    Offset rotatedTopRight = rotatePoint(topRight, rad, centerOrigin);
    Offset rotatedBottomLeft = rotatePoint(bottomLeft, rad, centerOrigin);
    Offset rotatedBottomRight = rotatePoint(bottomRight, rad, centerOrigin);

    double minX = min(
      min(rotatedTopLeft.dx, rotatedTopRight.dx),
      min(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double maxX = max(
      max(rotatedTopLeft.dx, rotatedTopRight.dx),
      max(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double minY = min(
      min(rotatedTopLeft.dy, rotatedTopRight.dy),
      min(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );
    double maxY = max(
      max(rotatedTopLeft.dy, rotatedTopRight.dy),
      max(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );

    double scaleX = outerBox.width / (maxX - minX);
    double scaleY = outerBox.height / (maxY - minY);

    return Offset(scaleX, scaleY);
  }

  @override
  Widget build2(BuildContext context) {
    double rotation = _elapsed * 20; // Degrees
    Size outerSize = Size(400, 200);
    Size innerSize = Size(400, 200);

    Offset scaleAdjustment =
        computeRotationScaleAdjustment(outerSize, rotation);

    return Center(
      child: SizedBox(
        width: outerSize.width,
        height: outerSize.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scaleX: scaleAdjustment.dx,
              scaleY: scaleAdjustment.dy,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: rotation * (pi / 180),
                alignment: Alignment.center,
                child: Container(
                  width: innerSize.width,
                  height: innerSize.height,
                  color: Colors.blue,
                  child: Text('Outer Box'),
                ),
              ),
            ),
            // Border to visualize outer box
            Container(
              width: outerSize.width,
              height: outerSize.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(132.0),
      child: LayoutBuilder(builder: (context, constraints) {
        CanvasObject par = CanvasObject(
          layout: FlexLayout(
            // direction: Axis.vertical,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            spacing: 5,
            mainAxisAlignment: FlexAlignment.start,
            crossAxisAlignment: FlexAlignment.start,
          ),
        );
        CanvasObject ch1 = CanvasObject(
          layoutData: FixedLayoutData(
            width: SizeConstraint.fixed(100),
            height: SizeConstraint.fixed(100),
          ),
        );
        CanvasObject ch2 = CanvasObject(
          layoutData: FlexLayoutData(
            flex: 1,
            max: 150,
            cross: SizeConstraint.fixed(150),
          ),
        );
        CanvasObject ch3 = CanvasObject(
          layoutData: FlexLayoutData(
            flex: 1,
            min: 180,
            max: 300,
            cross: SizeConstraint.fixed(150),
            scale: Offset(1, 1),
            // rotation: 90 * pi / 180,
            // rotation: _elapsed * pi * 0.1,
          ),
        );
        CanvasObject ch4 = CanvasObject(
          layoutData: FlexLayoutData(
            flex: 1,
            max: 150,
            cross: SizeConstraint.fixed(150),
          ),
        );
        CanvasObject ch5 = CanvasObject(
            layoutData: AbsoluteLayoutData(
          top: 50,
          left: 50,
          width: 100,
          height: 100,
        ));
        CanvasObject ch6 = CanvasObject(
          layoutData: AbsoluteLayoutData(
            bottom: 50,
            right: 50,
            width: 100,
            height: 100,
          ),
        );
        par.children = [ch1, ch2, ch3, ch4, ch5, ch6];
        var state = par.createState();
        par.attach(state);
        state.layout(constraints, TextDirection.ltr);
        return GroupWidget(
          size: constraints.biggest,
          children: [
            CanvasItemWidget(state: state),
          ],
        );
      }),
    );
  }
}
