import 'dart:math';

import 'package:flutter/services.dart';

Offset rotatePoint(Offset point, double angle) {
  final double cosAngle = cos(angle);
  final double sinAngle = sin(angle);
  return Offset(
    point.dx * cosAngle - point.dy * sinAngle,
    point.dx * sinAngle + point.dy * cosAngle,
  );
}

Offset proportionalDelta(Offset offset, double aspectRatio) {
  double dx = offset.dx;
  double dy = offset.dy;
  return Offset(min(dx, dy * aspectRatio), min(dy, dx / aspectRatio));
}

extension OffsetExtension on Offset {
  Offset multiply(Offset other) {
    return Offset(dx * other.dx, dy * other.dy);
  }

  Offset onlyX() {
    return Offset(dx, 0);
  }

  Offset onlyY() {
    return Offset(0, dy);
  }

  Offset divideBy(Offset other) {
    return Offset(dx / other.dx, dy / other.dy);
  }
}

int _findClosestAngle(double radians) {
  var degrees = radians * 180 / pi;
  degrees = degrees % 360;
  if (degrees < 0) {
    degrees += 360;
  }
  return ((degrees + 22.5) ~/ 45) % 8;
}

List<MouseCursor> _cursorRotations = [
  SystemMouseCursors.resizeUpDown, // 0
  SystemMouseCursors.resizeUpRight, // 45
  SystemMouseCursors.resizeLeftRight, // 90
  SystemMouseCursors.resizeDownRight, // 135
  SystemMouseCursors.resizeUpDown, // 180
  SystemMouseCursors.resizeDownLeft, // 225
  SystemMouseCursors.resizeLeftRight, // 270
  SystemMouseCursors.resizeUpLeft, // 315
];

const Map<ResizeCursor, ResizeCursor> _flipXMapper = {
  ResizeCursor.top: ResizeCursor.top,
  ResizeCursor.topRight: ResizeCursor.topLeft,
  ResizeCursor.right: ResizeCursor.left,
  ResizeCursor.bottomRight: ResizeCursor.bottomLeft,
  ResizeCursor.bottom: ResizeCursor.bottom,
  ResizeCursor.bottomLeft: ResizeCursor.bottomRight,
  ResizeCursor.left: ResizeCursor.right,
  ResizeCursor.topLeft: ResizeCursor.topRight,
};

const Map<ResizeCursor, ResizeCursor> _flipYMapper = {
  ResizeCursor.top: ResizeCursor.bottom,
  ResizeCursor.topRight: ResizeCursor.bottomRight,
  ResizeCursor.right: ResizeCursor.right,
  ResizeCursor.bottomRight: ResizeCursor.topRight,
  ResizeCursor.bottom: ResizeCursor.top,
  ResizeCursor.bottomLeft: ResizeCursor.topLeft,
  ResizeCursor.left: ResizeCursor.left,
  ResizeCursor.topLeft: ResizeCursor.bottomLeft,
};

enum ResizeCursor {
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  topLeft;

  const ResizeCursor();

  double get angle {
    return index * 45 * pi / 180;
  }

  ResizeCursor flip(bool flipX, bool flipY) {
    ResizeCursor cursor = this;
    if (flipX) {
      cursor = _flipXMapper[cursor]!;
    }
    if (flipY) {
      cursor = _flipYMapper[cursor]!;
    }
    return cursor;
  }

  MouseCursor getMouseCursor(double angle, bool flipX, bool flipY) {
    ResizeCursor cursor = flip(flipX, flipY);
    int index = _findClosestAngle(angle + cursor.angle);
    return _cursorRotations[index];
  }
}
