import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: _ForceUpdate(
        child: CanvasExample(),
      ),
    ),
  ));
}

class _ForceUpdate extends StatelessWidget {
  final Widget child;

  const _ForceUpdate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: UniqueKey(),
      child: child,
    );
  }
}

class CanvasExample extends StatefulWidget {
  const CanvasExample({super.key});

  @override
  State<CanvasExample> createState() => _CanvasExampleState();
}

double _degToRad(double deg) => deg * (pi / 180);
double _radToDeg(double rad) => rad * (180 / pi);

class _CanvasExampleState extends State<CanvasExample>
    with SingleTickerProviderStateMixin {
  Duration elapsed = Duration(seconds: 0);
  late Ticker _ticker;

  ResizeMode resizeMode = ResizeMode.resize;

  List<CanvasItem> items = [
    BoxCanvasItem(
      transformControlMode: TransformControlMode.show,
      transform: CanvasTransform(
        size: Size(200, 200),
        rotation: _degToRad(0),
        offset: Offset(-200, -200),
      ),
      widget: GestureDetector(
        onTap: () {
          print('tapped purple');
        },
        child: Container(
          color: Colors.purple,
        ),
      ),
      children: [
        BoxCanvasItem(
          transformControlMode: TransformControlMode.show,
          transform: CanvasTransform(
            size: Size(100, 100),
            // rotation: _degToRad(45),
            offset: Offset(150, 150),
            scale: Offset(1, 2),
          ),
          widget: GestureDetector(
            onTap: () {
              print('tapped green');
            },
            child: Container(
              color: Colors.green,
              child: Center(
                child: Text('brat'),
              ),
            ),
          ),
          children: [
            BoxCanvasItem(
              transformControlMode: TransformControlMode.show,
              transform: CanvasTransform(
                size: Size(50, 50),
                rotation: _degToRad(45),
                offset: Offset(120, 120),
                scale: Offset(1, 2),
              ),
              children: [
                BoxCanvasItem(
                  transformControlMode: TransformControlMode.show,
                  transform: CanvasTransform(
                    size: Size(100, 100),
                    // rotation: _degToRad(45),
                    offset: Offset(150, 150),
                    scale: Offset(1, 2),
                  ),
                  widget: GestureDetector(
                    onTap: () {
                      print('tapped green');
                    },
                    child: Container(
                      color: Colors.green,
                      child: Center(
                        child: Text('brat'),
                      ),
                    ),
                  ),
                  children: [
                    BoxCanvasItem(
                      transformControlMode: TransformControlMode.show,
                      transform: CanvasTransform(
                        size: Size(50, 50),
                        // rotation: _degToRad(45),
                        offset: Offset(120, 120),
                        scale: Offset(1, 1),
                      ),
                      children: [
                        BoxCanvasItem(
                          transformControlMode: TransformControlMode.show,
                          transform: CanvasTransform(
                            size: Size(100, 100),
                            rotation: _degToRad(45),
                            offset: Offset(150, 150),
                            scale: Offset(1, 1),
                          ),
                          widget: GestureDetector(
                            onTap: () {
                              print('tapped green');
                            },
                            child: Container(
                              color: Colors.green,
                              child: Center(
                                child: Text('brat'),
                              ),
                            ),
                          ),
                          children: [
                            BoxCanvasItem(
                              transformControlMode: TransformControlMode.show,
                              transform: CanvasTransform(
                                size: Size(50, 50),
                                rotation: _degToRad(45),
                                offset: Offset(120, 120),
                                scale: Offset(1, 1),
                              ),
                              children: [],
                              widget: GestureDetector(
                                onTap: () {
                                  print('tapped blue');
                                },
                                child: Container(
                                  color: Colors.blue,
                                  child: Center(
                                    child: Text('Hello'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      widget: GestureDetector(
                        onTap: () {
                          print('tapped blue');
                        },
                        child: Container(
                          color: Colors.blue,
                          child: Center(
                            child: Text('Hello'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              widget: GestureDetector(
                onTap: () {
                  print('tapped blue');
                },
                child: Container(
                  color: Colors.blue,
                  child: Center(
                    child: Text('Hello'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ];
  late CanvasViewport controller;

  @override
  void initState() {
    super.initState();
    controller = CanvasViewport(items: items);
    _ticker = createTicker((elapsed) {
      // setState(() {
      //   items[0].children[0].transform =
      //       items[0].children[0].transform.copyWith(
      //             rotation: _degToRad(elapsed.inMilliseconds / 50),
      //           );
      //   items[0].children[0].children[0].transform =
      //       items[0].children[0].children[0].transform.copyWith(
      //             rotation: _degToRad(elapsed.inMilliseconds / 10),
      //           );
      //   items[0].transform = items[0].transform.copyWith(
      //         rotation: _degToRad(elapsed.inMilliseconds / 100),
      //         // scale: Size(1 + sin(elapsed.inMilliseconds / 1000),
      //         //     1 + sin(elapsed.inMilliseconds / 1000) * 0.5),
      //       );
      // });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    controller.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          title: const Text('Resize Mode'),
          value: resizeMode == ResizeMode.resize,
          onChanged: (value) {
            setState(() {
              resizeMode = value! ? ResizeMode.resize : ResizeMode.scale;
            });
          },
        ),
        Expanded(
          child: Container(
            color: Colors.red,
            child: CanvasViewportWidget(
              controller: controller,
              resizeMode: resizeMode,
              control: StandardTransformControl(),
            ),
          ),
        ),
      ],
    );
  }
}
