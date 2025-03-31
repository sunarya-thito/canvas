import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/scheduler.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(ShadcnApp(
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: Sample(),
    ),
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

class _SampleState extends State<Sample> {
  final CanvasEditorController _controller = CanvasEditorController();

  double _rotation = 0.0;
  double _shearX = 0.0;
  double _shearY = 0.0;
  late CanvasObject parent;
  late CanvasRoot root;

  @override
  void initState() {
    super.initState();
    CanvasObject par = CanvasObject(
      debugLabel: 'parent',
      clipContent: true,
      borderRadius: BorderRadius.circular(150),
      layout: FlexLayout(
        // direction: Axis.vertical,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        // spacing: double.infinity,
        mainAxisAlignment: FlexAlignment.center,
        crossAxisAlignment: FlexAlignment.start,
      ),
      layoutData: AbsoluteLayoutData(
        top: 0,
        left: 0,
        width: 1200,
        height: 500,
        // rotation: _rotation * pi / 180,
        // rotation: _elapsed * pi * 0.1,
        // scale: Offset(2, 1),
        // shear: Offset(30 * 180 / pi, -60 * 180 / pi),
      ),
    );
    CanvasObject ch1 = CanvasObject(
      debugLabel: 'child1',
      layoutData: AbsoluteLayoutData(
        // width: SizeConstraint.fixed(100),
        // width: SizeConstraint.unconstrained(),
        // height: SizeConstraint.unconstrained(),
        top: -150,
        left: -150,
        width: 300,
        height: 300,
      ),
      layoutGrids: [
        // BlockLayoutGrid.stretch(
        //   count: 3,
        //   gutter: 25,
        //   margin: 50,
        // ),
        BlockLayoutGrid.center(
          count: 3,
          size: 75,
          gutter: 25,
          direction: Axis.vertical,
        )
      ],
    );
    CanvasObject ch2 = CanvasObject(
        debugLabel: 'child2',
        borderRadius: BorderRadius.circular(25),
        layoutData: FlexLayoutData(
          flex: 3,
          min: 150,
          max: 204,
          cross: SizeConstraint.fixed(150),
          shear: Offset(30 * pi / 180, -60 * pi / 180),
        ),
        layoutGrids: [
          GridLayoutGrid(),
        ]);
    CanvasObject ch3 = CanvasObject(
      debugLabel: 'child3',
      layoutData: FlexLayoutData(
        flex: 1,
        min: 150,
        max: 200,
        cross: SizeConstraint.unconstrained(),
      ),
    );
    CanvasObject ch4 = CanvasObject(
      debugLabel: 'child4',
      layoutData: FlexLayoutData(
        flex: 1,
        cross: SizeConstraint.fixed(200),
      ),
    );
    CanvasObject ch5 = CanvasObject(
      debugLabel: 'child5',
      layoutData: AbsoluteLayoutData(
        top: 150,
        left: 0.1,
        bottom: 150,
        right: 0.1,
        scaleHorizontal: true,
      ),
    );
    CanvasObject ch6 = CanvasObject(
      debugLabel: 'child6',
      layoutData: AbsoluteLayoutData(
        bottom: 50,
        right: 50,
        width: -100,
        height: 100,
      ),
    );
    par.children = [
      ch1,
      ch2,
      ch3,
      ch4,
      ch6,
      ch5,
    ];

    parent = par;
    root = CanvasRoot(children: [
      parent,
    ], debugLabel: 'root');
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
                root: root,
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
                          parent.layoutData = (parent.layoutData
                                  as AbsoluteLayoutData)
                              .copyWith(shear: Rotation(_rotation * pi / 180));
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
