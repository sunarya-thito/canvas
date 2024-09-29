import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late CanvasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(
      children: [
        BoxCanvasItem(
            decoration: GestureDetector(
              onTap: () {
                print('Red tapped');
              },
              child: Container(
                color: Colors.red,
                child: Center(
                  child: Text('Red'),
                ),
              ),
            ),
            layout: AbsoluteLayout(
              offset: Offset.zero,
              size: Size(100, 100),
              scale: Offset(2, 2),
              rotation: _degToRad(0),
            ),
            children: [
              BoxCanvasItem(
                decoration: GestureDetector(
                  onTap: () {
                    print('Green tapped');
                  },
                  child: Container(
                    color: Colors.green,
                  ),
                ),
                children: [
                  BoxCanvasItem(
                    decoration: GestureDetector(
                      onTap: () {
                        print('Orange tapped');
                      },
                      child: Container(
                        color: Colors.orange,
                      ),
                    ),
                    layout: AbsoluteLayout(
                      offset: Offset(50, 50),
                      size: Size(50, 50),
                      rotation: _degToRad(25),
                    ),
                  ),
                ],
                layout: AbsoluteLayout(
                  offset: Offset(100, 100),
                  size: Size(50, 50),
                  rotation: _degToRad(44),
                ),
              ),
            ]),
        BoxCanvasItem(
            decoration: GestureDetector(
              onTap: () {
                print('Purple tapped');
              },
              child: Container(
                color: Colors.purple,
              ),
            ),
            layout: AbsoluteLayout(
              offset: Offset(200, 0),
              size: Size(100, 100),
              scale: Offset(1, 1),
              rotation: _degToRad(25),
            ),
            children: [
              BoxCanvasItem(
                decoration: GestureDetector(
                  onTap: () {
                    print('Yellow tapped');
                  },
                  child: Container(
                    color: Colors.yellow,
                  ),
                ),
                children: [
                  BoxCanvasItem(
                    decoration: GestureDetector(
                      onTap: () {
                        print('Blue tapped');
                      },
                      child: Container(
                        color: Colors.blue,
                      ),
                    ),
                    layout: AbsoluteLayout(
                      offset: Offset(50, 50),
                      size: Size(50, 50),
                    ),
                  ),
                ],
                layout: AbsoluteLayout(
                  offset: Offset(100, 100),
                  size: Size(50, 50),
                  scale: Offset(2, 2),
                ),
              ),
            ]),
      ],
    );
  }

  bool _multiSelect = false; // using shift
  bool _proportionalResize = false; // using alt
  bool _symmetricResize = false; // using ctrl
  FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          if (event is KeyDownEvent) {
            setState(() {
              _multiSelect = true;
            });
          } else if (event is KeyUpEvent) {
            setState(() {
              _multiSelect = false;
            });
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.altLeft ||
            event.logicalKey == LogicalKeyboardKey.altRight) {
          if (event is KeyDownEvent) {
            setState(() {
              _proportionalResize = true;
            });
          } else if (event is KeyUpEvent) {
            setState(() {
              _proportionalResize = false;
            });
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          if (event is KeyDownEvent) {
            setState(() {
              _symmetricResize = true;
            });
          } else if (event is KeyUpEvent) {
            setState(() {
              _symmetricResize = false;
            });
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (event) {
          _focusNode.requestFocus();
        },
        child: CanvasViewport(
          controller: _controller,
          multiSelect: _multiSelect,
          proportionalResize: _proportionalResize,
          symmetricResize: _symmetricResize,
        ),
      ),
    );
  }
}
