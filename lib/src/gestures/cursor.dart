import 'dart:math';

import 'package:flutter/rendering.dart';

enum DirectionalCursor {
  top(SystemMouseCursors.resizeUpDown), // 0
  topRight(SystemMouseCursors.resizeUpRight), // 45
  right(SystemMouseCursors.resizeLeftRight), // 90
  bottomRight(SystemMouseCursors.resizeDownRight), // 135
  bottom(SystemMouseCursors.resizeUpDown), // 180
  bottomLeft(SystemMouseCursors.resizeDownLeft), // 225
  left(SystemMouseCursors.resizeLeftRight), // 270
  topLeft(SystemMouseCursors.resizeUpLeft); // 315

  static const length = 8; // number of directions
  static const double angleStep = 2 * pi / length; // = 45 degrees

  final MouseCursor cursor;

  const DirectionalCursor(this.cursor);

  DirectionalCursor rotate(int count) {
    int index = (this.index + count) % length;
    return DirectionalCursor.values[index];
  }

  DirectionalCursor rotateByAngle(double angle) {
    int index = ((this.index + (-angle / angleStep).round()) % length).toInt();
    return DirectionalCursor.values[index];
  }

  DirectionalCursor flip({bool horizontal = false, bool vertical = false}) {
    DirectionalCursor current = this;
    if (horizontal) {
      switch (current) {
        case DirectionalCursor.topLeft:
          current = DirectionalCursor.topRight;
          break;
        case DirectionalCursor.topRight:
          current = DirectionalCursor.topLeft;
          break;
        case DirectionalCursor.bottomLeft:
          current = DirectionalCursor.bottomRight;
          break;
        case DirectionalCursor.bottomRight:
          current = DirectionalCursor.bottomLeft;
          break;
        case DirectionalCursor.left:
          current = DirectionalCursor.right;
          break;
        case DirectionalCursor.right:
          current = DirectionalCursor.left;
          break;
        default:
          break;
      }
    }
    if (vertical) {
      switch (current) {
        case DirectionalCursor.topLeft:
          current = DirectionalCursor.bottomLeft;
          break;
        case DirectionalCursor.topRight:
          current = DirectionalCursor.bottomRight;
          break;
        case DirectionalCursor.bottomLeft:
          current = DirectionalCursor.topLeft;
          break;
        case DirectionalCursor.bottomRight:
          current = DirectionalCursor.topRight;
          break;
        case DirectionalCursor.left:
          current = DirectionalCursor.right;
          break;
        case DirectionalCursor.right:
          current = DirectionalCursor.left;
          break;
        default:
          break;
      }
    }
    return current;
  }
}
