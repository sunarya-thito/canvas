import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

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

double limitRadians(double radians) {
  radians = radians % (2 * pi);
  if (radians < 0) {
    radians += 2 * pi;
  }
  return radians;
}

/// Limit the degrees to the range of 0 to 90
double limitDegreesQuadrant(double degrees) {
  degrees = limitDegrees(degrees);
  if (degrees > 90 && degrees <= 180) {
    degrees = 180 - degrees;
  } else if (degrees > 180 && degrees <= 270) {
    degrees = degrees - 180;
  } else if (degrees > 270 && degrees <= 360) {
    degrees = 360 - degrees;
  }
  return degrees;
}

double limitRadiansQuadrant(double radians) {
  return degToRad(limitDegreesQuadrant(radToDeg(radians)));
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

Axis crossAxis(Axis axis) {
  return axis == Axis.horizontal ? Axis.vertical : Axis.horizontal;
}

void reparent(CanvasItem item, CanvasItem target) {
  CanvasItem? currentParent = item.parent;
  if (currentParent == target) {
    return;
  }
  ItemConstraints currentLayout = item.constraints;
  while (currentParent != null) {
    if (currentParent.isDescendant(target)) {
      break;
    }
    var parent = currentParent.parent;
    if (parent == null) {
      break;
    }
    currentLayout = currentLayout.transferToParent(currentParent.constraints);
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
        currentLayout = currentLayout.transferToChild(item.constraints);
      },
    );
  }
  item.constraints = currentLayout;
  var oldParent = item.parent;
  if (oldParent != null) {
    oldParent.removeChild(item);
  }
  target.addChild(item);
}

class MutableNotifier<T> extends ValueNotifier<T> {
  MutableNotifier(super.value);

  void notify() {
    notifyListeners();
  }

  ValueListenable<T> listenable([T Function(T value)? mapper]) {
    return MutableListenable(this, mapper);
  }
}

class MutableListenable<T> extends ValueListenable<T> {
  final MutableNotifier<T> _notifier;
  final T Function(T value)? _mapper;

  MutableListenable(this._notifier, [this._mapper]);

  @override
  T get value => _mapper?.call(_notifier.value) ?? _notifier.value;

  @override
  void addListener(listener) {
    _notifier.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _notifier.removeListener(listener);
  }
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

  Offset shear(Offset shear) {
    return Offset(
      dx + shear.dx * dy,
      shear.dy * dx + dy,
    );
  }

  Offset inverseShear(Offset shear) {
    return Offset(
      dx - shear.dx * dy,
      dy - shear.dy * dx,
    );
  }

  Offset only(Axis axis) {
    return axis == Axis.horizontal ? onlyX() : onlyY();
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

extension Matrix4Extension on Matrix4 {
  Offset transformPoint(Offset point) {
    final Vector3 vector = Vector3(point.dx, point.dy, 0);
    final Vector3 transformed = transform3(vector);
    return Offset(transformed.x, transformed.y);
  }

  Matrix4 removeTranslation() {
    final Matrix4 matrix = clone();
    matrix.setTranslation(Vector3.zero());
    return matrix;
  }

  Matrix4 inverse() {
    return Matrix4.inverted(this);
  }

  Polygon transformPolygon(Polygon polygon) {
    return Polygon(polygon.points.map(transformPoint).toList());
  }

  Offset get transformTranslation {
    return Offset(entry(0, 3), entry(1, 3));
  }

  double get transformRotation {
    // rotation = atan(M12 / M11)
    return atan2(entry(0, 1), entry(0, 0));
  }

  double get shearY {
    // shear(y) = atan(M22, M21) - PI / 2 - rotation
    return atan2(entry(1, 1), entry(1, 0)) - pi / 2 - transformRotation;
  }

  double get shearX {
    // shear(x) = atan(M12, M11) - rotation
    return atan2(entry(0, 1), entry(0, 0)) - transformRotation;
  }

  Offset get transformShear {
    // shear(x) = atan(M12, M11) - rotation
    double shearX = atan2(entry(0, 1), entry(0, 0)) - transformRotation;
    // shear(y) = atan(M22, M21) - PI / 2 - rotation
    double shearY =
        atan2(entry(1, 1), entry(1, 0)) - pi / 2 - transformRotation;
    return Offset(shearX, shearY);
  }

  Offset get transformScale {
    // scaleX = sqrt(M11^2 + M12^2)
    double scaleX = sqrt(entry(0, 0) * entry(0, 0) + entry(0, 1) * entry(0, 1));
    // scaleY = sqrt(M21^2 + M22^2) * cos(shear)
    double scaleY =
        sqrt(entry(1, 0) * entry(1, 0) + entry(1, 1) * entry(1, 1)) *
            cos(shearY);
    return Offset(scaleX, scaleY);
  }

  Matrix4 shearMatrix(Offset shear) {
    this[0] = this[0] + shear.dx * this[1];
    this[4] = this[4] + shear.dx * this[5];
    this[1] = this[1] + shear.dy * this[0];
    this[5] = this[5] + shear.dy * this[4];
    return this;
  }
}

Offset handleDeltaTransform(Offset delta, CanvasItem item) {
  Matrix4? parentTransform = item.nonTranslatedParentTransform;
  if (parentTransform != null) {
    return parentTransform.inverse().transformPoint(delta);
  }
  return delta;
}

Offset shearPoint(Offset point, Offset shear) {
  return Offset(
    point.dx + shear.dx * point.dy,
    shear.dy * point.dx + point.dy,
  );
}

mixin FixedTransformationMixin {
  Offset get offset;
  Size get size;
  double get rotation;
  Offset get shear;
  Offset get scale;

  Matrix4 get transformationMatrix {
    final Matrix4 matrix = Matrix4.identity();
    matrix.translate(offset.dx, offset.dy);
    matrix.rotateZ(rotation);
    matrix.shearMatrix(shear);
    matrix.scale(scale.dx, scale.dy);
    return matrix;
  }

  Matrix4 get inverseTransformationMatrix {
    return transformationMatrix.inverse();
  }

  Matrix4 get nonTranslatedTransformationMatrix {
    final Matrix4 matrix = Matrix4.identity();
    matrix.rotateZ(rotation);
    matrix.shearMatrix(shear);
    matrix.scale(scale.dx, scale.dy);
    return matrix;
  }

  Matrix4 get nonTranslatedInverseTransformationMatrix {
    return nonTranslatedTransformationMatrix.inverse();
  }
}
