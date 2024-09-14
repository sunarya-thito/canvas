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
  Duration elapsed = Duration.zero;
  late List<CanvasItem> items;
  late Ticker ticker;

  final CanvasViewportController controller = CanvasViewportController();

  @override
  void initState() {
    super.initState();
    _initializeItems();
    ticker = createTicker((elapsed) {
      setState(() {
        this.elapsed = elapsed;
        // for (final item in items) {
        //   item.transform = item.transform.copyWith(
        //     rotation: _degToRad(elapsed.inMilliseconds / 10),
        //   );
        // }
      });
    });
    ticker.start();
  }

  @override
  void dispose() {
    super.dispose();
    ticker.dispose();
  }

  void _initializeItems() {
    items = [
      TextItem(
        text: TextSpan(text: 'Hello World', style: TextStyle(fontSize: 24)),
        transform: CanvasItemTransform(
          position: Offset(500, 500),
          rotation: _degToRad(45),
        ),
        selected: true,
      )..calculateDefaultSize(),
      TextItem(
        text:
            TextSpan(text: 'Lorem Ipsum Dolor', style: TextStyle(fontSize: 24)),
        transform: CanvasItemTransform(
          position: Offset(50, 50),
          rotation: _degToRad(0),
        ),
      )..calculateDefaultSize(),
      BoxItem(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        transform: CanvasItemTransform(
          position: Offset(400, 400),
          size: const Size(200, 100),
          // rotation: _degToRad(elapsed.inMilliseconds / 10),
          rotation: _degToRad(25),
        ),
        selected: true,
        children: [
          BoxItem(
            decoration: BoxDecoration(
              color: Colors.purple,
            ),
            transform: CanvasItemTransform(
              position: Offset(90, 90),
              size: const Size(50, 50),
              // rotation: _degToRad(elapsed.inMilliseconds / 10),
              rotation: _degToRad(45),
            ),
            selected: true,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.red,
      child: CanvasViewport(
        controller: controller,
        items: items,
      ),
    );
  }
}
