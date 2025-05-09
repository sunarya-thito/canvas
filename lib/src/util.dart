import 'dart:math';
import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

double clampIgnoreSign(double value, double min, double max) {
  if (value.isNegative) {
    return value < -max
        ? -max
        : value > -min
            ? -min
            : value;
  } else {
    return value < min
        ? min
        : value > max
            ? max
            : value;
  }
}

extension SizeExtension on Size {
  bool containsIgnoreSign(Offset position) {
    double width = this.width;
    double height = this.height;
    if (width.isNaN) {
      width = 0;
    }
    if (height.isNaN) {
      height = 0;
    }
    bool flipHorizontal = width.isNegative;
    bool flipVertical = height.isNegative;
    double dx = position.dx;
    double dy = position.dy;
    if (flipHorizontal) {
      dx = -dx;
      width = -width;
    }
    if (flipVertical) {
      dy = -dy;
      height = -height;
    }
    return dx >= 0 && dy >= 0 && dx <= width && dy <= height;
  }

  Size constrainIgnoreSign(BoxConstraints? constraints) {
    if (constraints == null) {
      return this;
    }
    double minWidth = constraints.minWidth;
    double minHeight = constraints.minHeight;
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;
    return Size(clampIgnoreSign(width, minWidth, maxWidth),
        clampIgnoreSign(height, minHeight, maxHeight));
  }
}

extension OffsetExtension on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) {
      return Offset.zero;
    }
    return Offset(dx / length, dy / length);
  }
}

Matrix4 computeShearMatrix(Offset shear) {
  final shearMatrix = Matrix4.identity()
    ..setEntry(0, 1, tan(shear.dx))
    ..setEntry(1, 0, tan(shear.dy));
  final scaleMatrix = Matrix4.identity()
    ..setEntry(1, 1, cos(shear.dx))
    ..setEntry(0, 0, cos(shear.dy));
  return shearMatrix * scaleMatrix;
}

int sortChildren(CanvasItemState a, CanvasItemState b) {
  // if it has editorOffset, it should be on top
  if (a.dragOffset != null && b.dragOffset == null) {
    return 1;
  }
  if (a.dragOffset == null && b.dragOffset != null) {
    return -1;
  }
  return 0;
}

Offset computeShearFromMatrix(Matrix4 matrix) {
  final shearX = atan(matrix.entry(0, 1) / matrix.entry(1, 1));
  final shearY = atan(matrix.entry(1, 0) / matrix.entry(0, 0));
  return Offset(shearX, shearY);
}

Offset scaleFromMatrix(Matrix4 matrix) {
  final scaleX = sqrt(matrix.entry(0, 0) * matrix.entry(0, 0) +
      matrix.entry(1, 0) * matrix.entry(1, 0));
  final scaleY = sqrt(matrix.entry(0, 1) * matrix.entry(0, 1) +
      matrix.entry(1, 1) * matrix.entry(1, 1));
  return Offset(scaleX, scaleY);
}

double wrapRotation(double angle) {
  const tau = pi * 2;
  return (angle % tau + tau) % tau;
}

Matrix4 computeOrigin(Matrix4 transform, Offset origin) {
  final translateToOrigin = Matrix4.identity()
    ..setTranslationRaw(-origin.dx, -origin.dy, 0);
  final translateBack = Matrix4.identity()
    ..setTranslationRaw(origin.dx, origin.dy, 0);
  return translateBack * transform * translateToOrigin;
}

Offset rotatePoint(Offset point, double angle, [Offset origin = Offset.zero]) {
  final cosAngle = cos(angle);
  final sinAngle = sin(angle);
  final dx = point.dx - origin.dx;
  final dy = point.dy - origin.dy;
  final x = origin.dx + cosAngle * dx - sinAngle * dy;
  final y = origin.dy + sinAngle * dx + cosAngle * dy;
  return Offset(x, y);
}

Offset scalePoint(Offset point, Offset scale, [Offset origin = Offset.zero]) {
  final dx = (point.dx - origin.dx) * scale.dx + origin.dx;
  final dy = (point.dy - origin.dy) * scale.dy + origin.dy;
  return Offset(dx, dy);
}

Offset transformOffset(Offset point, Matrix4 transform,
    [Offset origin = Offset.zero]) {
  final vector = Vector3(point.dx - origin.dx, point.dy - origin.dy, 0);
  final transformed = transform.perspectiveTransform(vector);
  return Offset(transformed.x + origin.dx, transformed.y + origin.dy);
}

Size transformSize(Size size, Matrix4 transform,
    [Offset origin = Offset.zero]) {
  final vector = Vector3(size.width - origin.dx, size.height - origin.dy, 0);
  final transformed = transform.perspectiveTransform(vector);
  return Size(transformed.x + origin.dx, transformed.y + origin.dy);
}

double distanceBetweenRects(Rect a, Rect b) {
  double dx = 0.0;
  double dy = 0.0;

  if (a.right < b.left) {
    dx = b.left - a.right;
  } else if (b.right < a.left) {
    dx = a.left - b.right;
  }

  if (a.bottom < b.top) {
    dy = b.top - a.bottom;
  } else if (b.bottom < a.top) {
    dy = a.top - b.bottom;
  }

  return sqrt(dx * dx + dy * dy);
}

enum BorderType {
  solid,
  ridge,
  groove,
  inset,
  outset,
  dashed,
  dotted,
  double,
}

enum _BorderSide {
  top,
  left,
  right,
  bottom,
}

void paintCustomBorder(
  Canvas canvas,
  Size size, {
  required EdgeInsets borderWidths,
  required List<Color> borderColors, // [left, top, right, bottom]
  required BorderRadius borderRadius,
  required List<BorderType> borderTypes, // [left, top, right, bottom]
}) {
  final w = size.width;
  final h = size.height;

  final tl = Offset(0, 0);
  final tr = Offset(w, 0);
  final br = Offset(w, h);
  final bl = Offset(0, h);

  var tlInner = Offset(
    borderWidths.left,
    borderWidths.top,
  );
  var trInner = Offset(
    w - borderWidths.right,
    borderWidths.top,
  );
  var brInner = Offset(
    w - borderWidths.right,
    h - borderWidths.bottom,
  );
  var blInner = Offset(
    borderWidths.left,
    h - borderWidths.bottom,
  );

  Offset extendTowardDirection(Offset offset, double direction, double amount) {
    final dx = amount * cos(direction);
    final dy = amount * sin(direction);
    return Offset(offset.dx + dx, offset.dy + dy);
  }

  var center = Offset(w / 2, h / 2);

  tlInner = extendTowardDirection(
      tlInner, (tlInner - tl).direction, (center - tlInner).distance);
  trInner = extendTowardDirection(
      trInner, (trInner - tr).direction, (center - trInner).distance);
  brInner = extendTowardDirection(
      brInner, (brInner - br).direction, (center - brInner).distance);
  blInner = extendTowardDirection(
      blInner, (blInner - bl).direction, (center - blInner).distance);

  double nonNullLerp(double a, double b, double t) {
    return max(0, a + (b - a) * t);
  }

  RRect createRRect(double fractionalOffset) {
    return RRect.fromRectAndCorners(
      Rect.fromLTRB(
        nonNullLerp(0, borderWidths.left, fractionalOffset),
        nonNullLerp(0, borderWidths.top, fractionalOffset),
        nonNullLerp(w, w - borderWidths.right, fractionalOffset),
        nonNullLerp(h, h - borderWidths.bottom, fractionalOffset),
      ),
      topLeft: Radius.elliptical(
        nonNullLerp(borderRadius.topLeft.x,
            borderRadius.topLeft.x - borderWidths.left, fractionalOffset),
        nonNullLerp(borderRadius.topLeft.y,
            borderRadius.topLeft.y - borderWidths.top, fractionalOffset),
      ),
      topRight: Radius.elliptical(
        nonNullLerp(borderRadius.topRight.x,
            borderRadius.topRight.x - borderWidths.right, fractionalOffset),
        nonNullLerp(borderRadius.topRight.y,
            borderRadius.topRight.y - borderWidths.top, fractionalOffset),
      ),
      bottomLeft: Radius.elliptical(
        nonNullLerp(borderRadius.bottomLeft.x,
            borderRadius.bottomLeft.x - borderWidths.left, fractionalOffset),
        nonNullLerp(borderRadius.bottomLeft.y,
            borderRadius.bottomLeft.y - borderWidths.bottom, fractionalOffset),
      ),
      bottomRight: Radius.elliptical(
        nonNullLerp(borderRadius.bottomRight.x,
            borderRadius.bottomRight.x - borderWidths.right, fractionalOffset),
        nonNullLerp(borderRadius.bottomRight.y,
            borderRadius.bottomRight.y - borderWidths.bottom, fractionalOffset),
      ),
    );
  }

  Path? cachedRidgePath;
  Path? cachedGroovePath;
  Path? cachedDoublePath;
  Path? cachedSolidPath;
  Path? cachedNonSolidPath;
  Path? cachedInnerPath;
  Path? cachedOuterPath;

  Path getRidgePath() {
    cachedRidgePath ??= Path()
      ..addRRect(createRRect(0.5))
      ..addRRect(createRRect(0.0))
      ..fillType = PathFillType.evenOdd;
    return cachedRidgePath!;
  }

  Path getNonSolidPath() {
    cachedNonSolidPath ??= Path()..addRRect(createRRect(0.5));
    return cachedNonSolidPath!;
  }

  Path getInnerPath() {
    cachedInnerPath ??= Path()..addRRect(createRRect(0.0));
    return cachedInnerPath!;
  }

  Path getOuterPath() {
    cachedOuterPath ??= Path()..addRRect(createRRect(1.0));
    return cachedOuterPath!;
  }

  Path getGroovePath() {
    cachedGroovePath ??= Path()
      ..addRRect(createRRect(0.5))
      ..addRRect(createRRect(1.0))
      ..fillType = PathFillType.evenOdd;
    return cachedGroovePath!;
  }

  Path getDoublePath() {
    cachedDoublePath ??= Path()
      ..addRRect(createRRect(0.0))
      ..addRRect(createRRect(0.33))
      ..addRRect(createRRect(0.66))
      ..addRRect(createRRect(1.0))
      ..fillType = PathFillType.evenOdd;
    return cachedDoublePath!;
  }

  Path getSolidPath() {
    cachedSolidPath ??= Path()
      ..addRRect(createRRect(0.0))
      ..addRRect(createRRect(1.0))
      ..fillType = PathFillType.evenOdd;
    return cachedSolidPath!;
  }

  Color darkenColor(Color color, double amount) {
    return color.withValues(
      red: color.r * (1 - amount),
      green: color.g * (1 - amount),
      blue: color.b * (1 - amount),
    );
  }

  void drawSide(
    Canvas canvas,
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    Color color,
    _BorderSide borderSide,
    BorderType borderType,
  ) {
    final triangleClipPath = Path();
    triangleClipPath.moveTo(p0.dx, p0.dy);
    triangleClipPath.lineTo(p1.dx, p1.dy);
    triangleClipPath.lineTo(p2.dx, p2.dy);
    triangleClipPath.lineTo(p3.dx, p3.dy);
    triangleClipPath.close();

    if (borderType == BorderType.dashed) {
      var metrics = getInnerPath().computeMetrics();

      double dashWidth = borderSide == _BorderSide.left
          ? borderWidths.left
          : borderSide == _BorderSide.top
              ? borderWidths.top
              : borderSide == _BorderSide.right
                  ? borderWidths.right
                  : borderWidths.bottom;
      double dashSpace = dashWidth * 2;
      double dashLength = dashWidth + dashSpace;
      Path dashes = Path();
      ;
      for (final metric in metrics) {
        final length = metric.length;
      }
      Path combinedPath = Path()
        ..addPath(dashes, Offset.zero)
        ..addPath(getSolidPath(), Offset.zero)
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(
          Path.combine(
            PathOperation.intersect,
            combinedPath,
            triangleClipPath,
          ),
          Paint()..color = color);
      return;
    }

    if (borderType == BorderType.dotted) {
      var metrics = getNonSolidPath().computeMetrics();
      double circleDiameter = borderSide == _BorderSide.left
          ? borderWidths.left
          : borderSide == _BorderSide.top
              ? borderWidths.top
              : borderSide == _BorderSide.right
                  ? borderWidths.right
                  : borderWidths.bottom;
      double radius = circleDiameter / 2;
      Path circles = Path();
      int circleIndex = 0;
      for (final metric in metrics) {
        final length = metric.length;
        for (double i = 0; i < length; i += circleDiameter) {
          final tangent = metric.getTangentForOffset(i);
          if (tangent != null) {
            if (!triangleClipPath.contains(tangent.position)) {
              continue;
            }
            if (circleIndex % 2 == 0) {
              circles.addOval(
                Rect.fromCircle(
                  center: tangent.position,
                  radius: radius,
                ),
              );
            }
            circleIndex++;
          }
        }
      }
      canvas.drawPath(
          Path.combine(
            PathOperation.intersect,
            circles,
            triangleClipPath,
          ),
          Paint()..color = color);
      return;
    }

    Path? sidePath;
    Path? darkenPath;
    if (borderType == BorderType.solid) {
      sidePath = Path.combine(
        PathOperation.intersect,
        getSolidPath(),
        triangleClipPath,
      );
    } else if (borderType == BorderType.inset) {
      if (borderSide == _BorderSide.left || borderSide == _BorderSide.top) {
        darkenPath = Path.combine(
          PathOperation.intersect,
          getSolidPath(),
          triangleClipPath,
        );
      } else {
        sidePath = Path.combine(
          PathOperation.intersect,
          getSolidPath(),
          triangleClipPath,
        );
      }
    } else if (borderType == BorderType.outset) {
      if (borderSide == _BorderSide.right || borderSide == _BorderSide.bottom) {
        darkenPath = Path.combine(
          PathOperation.intersect,
          getSolidPath(),
          triangleClipPath,
        );
      } else {
        sidePath = Path.combine(
          PathOperation.intersect,
          getSolidPath(),
          triangleClipPath,
        );
      }
    } else if (borderType == BorderType.dashed) {
      sidePath = Path.combine(
        PathOperation.intersect,
        getSolidPath(),
        triangleClipPath,
      );
    } else if (borderType == BorderType.ridge) {
      sidePath = Path.combine(
        PathOperation.intersect,
        getRidgePath(),
        triangleClipPath,
      );
      darkenPath = Path.combine(
        PathOperation.intersect,
        getGroovePath(),
        triangleClipPath,
      );
    } else if (borderType == BorderType.groove) {
      sidePath = Path.combine(
        PathOperation.intersect,
        getGroovePath(),
        triangleClipPath,
      );
      darkenPath = Path.combine(
        PathOperation.intersect,
        getRidgePath(),
        triangleClipPath,
      );
    } else if (borderType == BorderType.double) {
      sidePath = Path.combine(
        PathOperation.intersect,
        getDoublePath(),
        triangleClipPath,
      );
    } else {
      throw ArgumentError('Unsupported border type: $borderType');
    }

    if (sidePath != null) {
      canvas.drawPath(sidePath, Paint()..color = color);
    }
    if (darkenPath != null) {
      canvas.drawPath(darkenPath, Paint()..color = darkenColor(color, 0.2));
    }
  }

  // Draw each side with the corresponding color and width
  drawSide(
    canvas,
    tl,
    bl,
    blInner,
    tlInner,
    borderColors[0],
    _BorderSide.left,
    borderTypes[0],
  );
  drawSide(
    canvas,
    tl,
    tr,
    trInner,
    tlInner,
    borderColors[1],
    _BorderSide.top,
    borderTypes[1],
  );
  drawSide(
    canvas,
    tr,
    br,
    brInner,
    trInner,
    borderColors[2],
    _BorderSide.right,
    borderTypes[2],
  );
  drawSide(
    canvas,
    bl,
    br,
    brInner,
    blInner,
    borderColors[3],
    _BorderSide.bottom,
    borderTypes[3],
  );
}
