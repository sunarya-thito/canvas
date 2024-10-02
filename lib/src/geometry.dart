import 'dart:math';
import 'dart:ui';

import 'package:canvas/src/util.dart';

const kDeg90 = 90.0 * pi / 180;

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
