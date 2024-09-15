import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: CanvasExample(),
    ),
  ));
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

  CanvasTransform transform = CanvasTransform(
    size: Size(100, 100),
    rotation: _degToRad(45),
    offset: Offset(300, 300),
  );
  CanvasTransform transform2 = CanvasTransform(
    size: Size(50, 50),
    rotation: _degToRad(25),
    offset: Offset(0, 0),
    scale: Size(1, 1),
  );

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        // this.elapsed = elapsed;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          print('tapped container');
        },
        child: CanvasGroup(
          children: [
            CanvasItem(
              transform: transform,
              children: [
                CanvasItem(
                  transform: transform2,
                  background: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      print('tapped 2');
                    },
                    child: Container(
                      color: Colors.green,
                      child: Center(
                        child: Text('Hello'),
                      ),
                    ),
                  ),
                ),
              ],
              controls: [
                TransformControl(
                  transform: transform2,
                ),
              ],
              background: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  print('tapped');
                },
                child: Container(
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
