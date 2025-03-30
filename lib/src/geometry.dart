import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

const kDeg90 = 90.0 * pi / 180;

class Rotation extends Offset {
  const Rotation(double angle) : super(angle, -angle);
}

Rect normalizeRect(Rect rect) {
  return Offset.zero & rect.size;
}

double rotationFromShear(Offset shear) {
  // (rotation - (-rotation)) / 2
  // (rotation + rotation) / 2
  return -(shear.dx - shear.dy) / 2;
}

Offset resizeShear(Size newOuterSize, Offset shear) {
  // anjirlah pusing pala gw cok
  double newWidth = newOuterSize.width;
  double newHeight = newOuterSize.height;
  //    tan(newShearX) =   nW
  //                     ------- * tan(shearX)
  //                       nH
  //    tan(newShearX) =   nH
  //                     ------- * tan(shearY)
  //                       nW
  double tanShearXNew = (newWidth / newHeight) * tan(shear.dx);
  double tanShearYNew = (newHeight / newWidth) * tan(shear.dy);
  //   newShearX = tan-1(tanShearXNew)
  //   newShearY = tan-1(tanShearYNew)
  double newShearX = atan(tanShearXNew); // atan -> tan-1 or arc tangent
  double newShearY = atan(tanShearYNew);
  return Offset(newShearX, newShearY);
}

Offset normalizeOffset(Offset offset) {
  final double length = offset.distance;
  return length > 0 ? offset / length : offset;
}

Matrix4 computeShearMatrix(double shearX, double shearY,
    {Matrix4? parent, Offset? origin}) {
  var result = Matrix4.identity();
  if (origin != null) {
    result.translate(origin.dx, origin.dy);
  }
  var shearXMatrix = Matrix4.identity()
    ..setEntry(0, 1, tan(shearX))
    ..setEntry(1, 0, tan(shearY));
  var shearYMatrix = Matrix4.identity()
    ..setEntry(1, 1, cos(shearX))
    ..setEntry(0, 0, cos(shearY));
  result = shearXMatrix * shearYMatrix * result;
  if (origin != null) {
    result.translate(-origin.dx, -origin.dy);
  }
  if (parent != null) {
    result = parent * result;
  }
  return result;
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

enum PolygonOverlapResult {
  none,
  partial,
  full,
}

class Polygon {
  static const Polygon empty = Polygon([]);
  final List<Offset> points;

  const Polygon(this.points);

  factory Polygon.fromRect(Rect rect) {
    return Polygon([
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ]);
  }

  factory Polygon.fromLTRB(
      double left, double top, double right, double bottom) {
    return Polygon([
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom),
    ]);
  }

  factory Polygon.fromLTWH(
      double left, double top, double width, double height) {
    return Polygon([
      Offset(left, top),
      Offset(left + width, top),
      Offset(left + width, top + height),
      Offset(left, top + height),
    ]);
  }

  Path get path {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
    }
    return path;
  }

  Path computeRoundedRectPath(BorderRadius borderRadius, Matrix4 transform) {
    assert(points.length == 4,
        'Polygon must have 4 points to compute rounded rect path');
    final path = Path();

    final List<double> radii = [
      borderRadius.topLeft.x,
      borderRadius.topRight.x,
      borderRadius.bottomRight.x,
      borderRadius.bottomLeft.x,
    ];

    for (int i = 0; i < 4; i++) {
      final Offset p1 = points[i];
      final Offset p2 = points[(i + 1) % 4];
      final Offset p0 = points[(i - 1 + 4) % 4];

      final double radius = radii[i];

      if (radius > 0) {
        final Offset v1 = normalizeOffset(p1 - p0) * radius;
        final Offset v2 = normalizeOffset(p2 - p1) * radius;

        final Offset cornerStart = p1 - v1;
        final Offset cornerEnd = p1 + v2;

        final Offset transformedCornerStart =
            MatrixUtils.transformPoint(transform, cornerStart);
        final Offset transformedCornerEnd =
            MatrixUtils.transformPoint(transform, cornerEnd);
        final Offset transformedP1 = MatrixUtils.transformPoint(transform, p1);

        if (i == 0) {
          path.moveTo(transformedCornerStart.dx, transformedCornerStart.dy);
        } else {
          path.lineTo(transformedCornerStart.dx, transformedCornerStart.dy);
        }

        path.arcToPoint(
          transformedCornerEnd,
          radius: Radius.circular(radius),
          largeArc: false,
          clockwise: true,
        );
      } else {
        final Offset transformedP1 = MatrixUtils.transformPoint(transform, p1);
        if (i == 0) {
          path.moveTo(transformedP1.dx, transformedP1.dy);
        } else {
          path.lineTo(transformedP1.dx, transformedP1.dy);
        }
      }
    }

    path.close();
    return path;
  }

  Size get boundingBoxSize {
    final box = boundingBox;
    return Size(box.width, box.height);
  }

  Rect get boundingBox {
    if (points.isEmpty) {
      return Rect.zero;
    }
    double left = points[0].dx;
    double right = points[0].dx;
    double top = points[0].dy;
    double bottom = points[0].dy;
    for (var i = 1; i < points.length; i++) {
      left = min(left, points[i].dx);
      right = max(right, points[i].dx);
      top = min(top, points[i].dy);
      bottom = max(bottom, points[i].dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Polygon transform(Matrix4 transform, [Offset origin = Offset.zero]) {
    return Polygon(
        points.map((p) => transformOffset(p, transform, origin)).toList());
  }

  Polygon translate(Offset offset) {
    return Polygon(points.map((p) => p + offset).toList());
  }

  Polygon rotate(double angle, [Offset origin = Offset.zero]) {
    return Polygon(points.map((p) {
      final translated = p - origin;
      final rotated = rotatePoint(translated, angle);
      return rotated + origin;
    }).toList());
  }

  Polygon scale(Offset scale, [Offset origin = Offset.zero]) {
    return Polygon(points.map((p) {
      final translated = p - origin;
      final scaled = Offset(translated.dx * scale.dx, translated.dy * scale.dy);
      return scaled + origin;
    }).toList());
  }

  double get area {
    if (points.length < 3) {
      return 0;
    }
    double sum = 0;
    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      sum += p1.dx * p2.dy - p2.dx * p1.dy;
    }
    return sum.abs() / 2;
  }

  bool contains(Offset point) {
    var inside = false;

    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      if ((p1.dy > point.dy) != (p2.dy > point.dy) &&
          point.dx <
              (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx) {
        inside = !inside;
      }
    }

    return inside;
  }

  bool containsPolygon(Polygon other) {
    for (var i = 0; i < other.points.length; i++) {
      if (!contains(other.points[i])) {
        return false;
      }
    }
    if (overlaps(other)) {
      return false;
    }
    return true;
  }

  bool overlaps(Polygon other) {
    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      for (var j = 0; j < other.points.length; j++) {
        final q1 = other.points[j];
        final q2 = other.points[(j + 1) % other.points.length];
        if (_edgesIntersect(p1, p2, q1, q2)) {
          return true;
        }
      }
    }
    for (var i = 0; i < points.length; i++) {
      if (other.contains(points[i])) {
        return true;
      }
    }
    return false;
  }

  Polygon intersect(Polygon other) {
    List<Offset> subjectPoints = List.from(points);

    for (var i = 0; i < other.points.length; i++) {
      Offset clipEdgeStart = other.points[i];
      Offset clipEdgeEnd = other.points[(i + 1) % other.points.length];

      subjectPoints = _clipPolygon(subjectPoints, clipEdgeStart, clipEdgeEnd);

      if (subjectPoints.isEmpty) {
        return empty;
      }
    }

    return Polygon(subjectPoints);
  }

  PolygonOverlapResult overlap(Polygon other) {
    if (containsPolygon(other)) {
      return PolygonOverlapResult.full;
    }
    if (overlaps(other)) {
      return PolygonOverlapResult.partial;
    }
    return PolygonOverlapResult.none;
  }

  @override
  String toString() {
    return 'Polygon{points: $points}';
  }
}

bool _edgesIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
  return _onDifferentSides(p1, p2, q1, q2) && _onDifferentSides(q1, q2, p1, p2);
}

bool _onDifferentSides(Offset p, Offset q, Offset r, Offset s) {
  return _cross(p, q, r) * _cross(p, q, s) < 0;
}

double _cross(Offset a, Offset b, Offset c) {
  return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
}

List<Offset> _clipPolygon(
    List<Offset> polygon, Offset clipEdgeStart, Offset clipEdgeEnd) {
  List<Offset> clippedPolygon = [];

  for (var i = 0; i < polygon.length; i++) {
    Offset currentPoint = polygon[i];
    Offset previousPoint = polygon[(i - 1) % polygon.length];

    bool currentInside = _isInside(clipEdgeStart, clipEdgeEnd, currentPoint);
    bool previousInside = _isInside(clipEdgeStart, clipEdgeEnd, previousPoint);

    if (currentInside) {
      if (!previousInside) {
        Offset? intersection = _intersection(
            clipEdgeStart, clipEdgeEnd, previousPoint, currentPoint);
        if (intersection != null) {
          clippedPolygon.add(intersection);
        }
      }
      clippedPolygon.add(currentPoint);
    } else if (previousInside) {
      Offset? intersection = _intersection(
          clipEdgeStart, clipEdgeEnd, previousPoint, currentPoint);
      if (intersection != null) {
        clippedPolygon.add(intersection);
      }
    }
  }

  return clippedPolygon;
}

bool _isInside(Offset edgeStart, Offset edgeEnd, Offset point) {
  return (edgeEnd.dx - edgeStart.dx) * (point.dy - edgeStart.dy) -
          (edgeEnd.dy - edgeStart.dy) * (point.dx - edgeStart.dx) >=
      0;
}

Offset? _intersection(Offset p1, Offset p2, Offset q1, Offset q2) {
  double a1 = p2.dy - p1.dy;
  double b1 = p1.dx - p2.dx;
  double c1 = a1 * p1.dx + b1 * p1.dy;

  double a2 = q2.dy - q1.dy;
  double b2 = q1.dx - q2.dx;
  double c2 = a2 * q1.dx + b2 * q1.dy;

  double determinant = a1 * b2 - a2 * b1;

  if (determinant == 0) {
    return null;
  }

  double x = (b2 * c1 - b1 * c2) / determinant;
  double y = (a1 * c2 - a2 * c1) / determinant;
  return Offset(x, y);
}
