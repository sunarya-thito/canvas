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
    enableScrollInterception: false,
  ));
}

class Sample extends StatefulWidget {
  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> with SingleTickerProviderStateMixin {
  double _elapsed = 0.0;
  final CanvasEditorController _controller = CanvasEditorController();

  late Ticker _ticker;
  double _rotation = 0.0;
  late CanvasObject parent;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed.inMilliseconds / 1000;
      });
    });
    // _ticker.start();
    CanvasObject par = CanvasObject(
      debugLabel: 'parent',
      layout: FlexLayout(
        // direction: Axis.vertical,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        // spacing: double.infinity,
        mainAxisAlignment: FlexAlignment.center,
        crossAxisAlignment: FlexAlignment.start,
      ),
      layoutData: AbsoluteLayoutData(
        top: 50,
        left: 50,
        width: 1200,
        height: 500,
        // rotation: _rotation * pi / 180,
        // rotation: _elapsed * pi * 0.1,
        // scale: Offset(2, 1),
      ),
    );
    CanvasObject ch1 = CanvasObject(
      debugLabel: 'child1',
      layoutData: FixedLayoutData(
        // width: SizeConstraint.fixed(100),
        width: SizeConstraint.unconstrained(),
        height: SizeConstraint.unconstrained(),
      ),
    );
    CanvasObject ch2 = CanvasObject(
      debugLabel: 'child2',
      layoutData: FlexLayoutData(
        flex: 3,
        min: 150,
        max: 200,
        cross: SizeConstraint.fixed(150),
      ),
    );
    CanvasObject ch3 = CanvasObject(
      debugLabel: 'child3',
      layoutData: FlexLayoutData(
        flex: 1,
        min: 150,
        max: 200,
        cross: SizeConstraint.unconstrained(),
        // scale: Offset(2, 1),
        // rotation: 35 * pi / 180,
        // rotation: _elapsed * pi * 0.1,
      ),
    );
    CanvasObject ch4 = CanvasObject(
      debugLabel: 'child4',
      layoutData: FlexLayoutData(
        flex: 1,
        cross: SizeConstraint.fixed(150),
      ),
    );
    CanvasObject ch5 = CanvasObject(
      debugLabel: 'child5',
      layoutData: AbsoluteLayoutData(
        top: 50,
        left: 50,
        width: 100,
        height: 100,
        bottom: 50,
        right: 50,
      ),
    );
    CanvasObject ch6 = CanvasObject(
      debugLabel: 'child6',
      layoutData: AbsoluteLayoutData(
        bottom: 50,
        right: 50,
        width: 100,
        height: 100,
      ),
    );
    par.children = [
      ch5,
      ch1,
      // ch2,
      ch3,
      ch4,
      ch6,
    ];

    parent = par;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: CanvasEditor(
                controller: _controller,
                items: [
                  parent,
                ],
              ),
            ),
          ),
          Positioned(
              bottom: 50,
              right: 50,
              width: 300,
              child: Container(
                color: Colors.black.withAlpha(128),
                padding: EdgeInsets.all(10),
                // create slider
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rotation: $_rotation'),
                    Slider(
                      value: SliderValue.single(_rotation),
                      min: 0,
                      max: 360,
                      onChanged: (value) {
                        setState(() {
                          _rotation = value.value;
                          parent.layoutData =
                              (parent.layoutData as AbsoluteLayoutData)
                                  .copyWith(rotation: _rotation * pi / 180);
                        });
                      },
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
