import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Size calculateTextSize(TextSpan textSpan,
    [TextDirection textDirection = TextDirection.ltr]) {
  final TextPainter textPainter = TextPainter(
    text: textSpan,
    textDirection: textDirection,
  )..layout();
  return textPainter.size;
}

double degToRad(double degrees) {
  return degrees * pi / 180;
}

double radToDeg(double radians) {
  return radians * 180 / pi;
}

double limitDegrees(double degrees) {
  degrees = degrees % 360;
  if (degrees < 0) {
    degrees += 360;
  }
  return degrees;
}

Offset rotatePoint(Offset point, double angle) {
  final double cosAngle = cos(angle);
  final double sinAngle = sin(angle);
  return Offset(
    point.dx * cosAngle - point.dy * sinAngle,
    point.dx * sinAngle + point.dy * cosAngle,
  );
}

CanvasItem? findReparentTarget(
    CanvasItem item, CanvasHitTestResult hitTestResult) {
  // print('-------------');
  for (final path in hitTestResult.path) {
    final target = path.item;
    if (target == item) {
      continue;
    }
    // print('target: $target');
    var parent = target.parent;
    bool parentFocused = true;
    bool parentClipped = false;
    CanvasItem? currentParent = parent;
    while (currentParent != null) {
      if (currentParent.opaque && currentParent.clipContent) {
        parentClipped = true;
        break;
      }
      currentParent = currentParent.parent;
    }
    if (parentClipped) {
      if (parentFocused) {
        return target;
      }
    } else {
      return target;
    }
  }
  return null;
}

void reparent(CanvasItem item, CanvasItem target) {
  CanvasItem? currentParent = item.parent;
  if (currentParent == target) {
    return;
  }
  Layout currentLayout = item.layout;
  while (currentParent != null) {
    if (currentParent.isDescendantOf(target)) {
      break;
    }
    var parent = currentParent.parent;
    if (parent == null) {
      break;
    }
    currentLayout = currentLayout.transferToParent(currentParent.layout);
    currentParent = parent;
  }
  // currentParent is the common ancestor of item and target
  if (currentParent != null) {
    currentParent.visitTo(
      target,
      (item) {
        if (item == currentParent) {
          return;
        }
        currentLayout = currentLayout.transferToChild(item.layout);
      },
    );
  }
  item.layout = currentLayout;
  var oldParent = item.parent;
  if (oldParent != null) {
    oldParent.removeChild(item);
  }
  target.addChild(item);
}

bool iterableEquals<T>(Iterable<T> a, Iterable<T> b) {
  if (a == b) {
    return true;
  }
  if (a is List<T> && b is List<T>) {
    return listEquals(a, b);
  }
  if (a is Set<T> && b is Set<T>) {
    return setEquals(a, b);
  }
  return a.length == b.length && a.every(b.contains);
}

Offset proportionalDelta(Offset offset, double aspectRatio) {
  if (aspectRatio == 0) {
    return offset;
  }
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

  Offset flipAxis() {
    return Offset(dy, dx);
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
