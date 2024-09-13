import 'package:canvas/canvas.dart';
import 'package:flutter/material.dart';

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

class _CanvasExampleState extends State<CanvasExample> {
  final List<CanvasItem> items = [
    BoxCanvasItem(
      color: Colors.purple,
      transform: CanvasItemTransform(
        size: Size(100, 100),
        position: Offset(400, 400),
        rotation: degToRad(35),
      ),
      selected: true,
    ),
    TextCanvasItem(
      text: 'Hello World',
      style: TextStyle(
        fontSize: 48,
      ),
      offset: Offset(50, 50),
      selected: true,
    ),
    TextCanvasItem(
      text: 'Lorem Ipsum',
      style: TextStyle(),
      offset: Offset(100, 300),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: CanvasViewport(
        items: items,
      ),
    );
  }
}
