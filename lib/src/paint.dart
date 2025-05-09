import 'dart:math';
import 'dart:ui';

Path drawLine({
  required PathMetric pathMetric,
  StrokeCap cap = StrokeCap.butt,
  StrokeJoin join = StrokeJoin.round,
  required double Function(double progress)
      strokeWidth, // progress in [0, 1], where 0 is the start of the path and 1 is the end
  double miterLimit = 4,
}) {
  final path = Path();
  final length = pathMetric.length;
  // draw the first line segment
  for (double index = 0; index < length; index++) {
    StrokeJoin currentJoin = join;
    final tangent = pathMetric.getTangentForOffset(index);
    if (tangent == null) {
      continue;
    }
    final point = tangent.position;
    double progress = index / length;
    double width = strokeWidth(progress);
    if (index > 0 && index + 1 < length) {
      double? miterAngle;
      final prevTangent = pathMetric.getTangentForOffset(index - 1);
      final nextTangent = pathMetric.getTangentForOffset(index + 1);
      assert(prevTangent != null && nextTangent != null);
      final prevPoint = prevTangent!.position;
      final nextPoint = nextTangent!.position;
      miterAngle = _calculateMiterAngle(prevPoint, point, nextPoint);
      if (join == StrokeJoin.miter) {
        if (miterAngle > miterLimit) {
          currentJoin = StrokeJoin.bevel;
        }
      }
      double angle = (point - nextPoint).direction + pi / 2;
      if (join == StrokeJoin.bevel) {
        path.lineTo(
          point.dx + width * cos(angle) * 0.5,
          point.dy + width * sin(angle) * 0.5,
        );
      }
    } else {
      if (index == 0 && index + 1 < length) {
        // start cap
        double? nextMiterAngle;
        final nextTangent = pathMetric.getTangentForOffset(index + 1);
        if (nextTangent != null) {
          final nextPoint = nextTangent.position;
          nextMiterAngle = (nextPoint - point).direction;
        }
        assert(nextMiterAngle != null);
        double offsetAngle = nextMiterAngle! - pi / 2;
        if (cap == StrokeCap.butt) {
          path.moveTo(point.dx, point.dy);
          path.lineTo(point.dx + width * cos(offsetAngle),
              point.dy + width * sin(offsetAngle));
        } else if (cap == StrokeCap.round) {
          path.moveTo(point.dx + width * cos(-nextMiterAngle) * 0.5,
              point.dy + width * sin(-nextMiterAngle) * 0.5);
          path.conicTo(
              point.dx +
                  width * cos(-nextMiterAngle) * 0.5 +
                  width * cos(offsetAngle),
              point.dy +
                  width * sin(-nextMiterAngle) * 0.5 +
                  width * sin(offsetAngle),
              point.dx + width * cos(offsetAngle),
              point.dy + width * sin(offsetAngle),
              0.5);
        } else if (cap == StrokeCap.square) {
          path.moveTo(
            point.dx + width * cos(-nextMiterAngle) * 0.5,
            point.dy + width * sin(-nextMiterAngle) * 0.5,
          );
          path.lineTo(
            point.dx +
                width * cos(offsetAngle) +
                width * cos(-nextMiterAngle) * 0.5,
            point.dy +
                width * sin(offsetAngle) +
                width * sin(-nextMiterAngle) * 0.5,
          );
          path.lineTo(
            point.dx + width * cos(offsetAngle),
            point.dy + width * sin(offsetAngle),
          );
        }
      } else if (index > 0 && index + 1 >= length) {
        // end cap
        double? prevMiterAngle;
        final prevTangent = pathMetric.getTangentForOffset(index - 1);
        if (prevTangent != null) {
          final prevPoint = prevTangent.position;
          prevMiterAngle = (point - prevPoint).direction;
        }
        assert(prevMiterAngle != null);
        double offsetAngle = prevMiterAngle! + pi / 2;
        if (cap == StrokeCap.butt) {
          path.lineTo(point.dx + width * cos(offsetAngle),
              point.dy + width * sin(offsetAngle));
        } else if (cap == StrokeCap.round) {
          path.conicTo(
              point.dx + width * cos(prevMiterAngle) * 0.5,
              point.dy + width * sin(prevMiterAngle) * 0.5,
              point.dx + width * cos(offsetAngle),
              point.dy + width * sin(offsetAngle),
              0.5);
        } else if (cap == StrokeCap.square) {
          path.lineTo(
            point.dx + width * cos(prevMiterAngle) * 0.5,
            point.dy + width * sin(prevMiterAngle) * 0.5,
          );
          path.lineTo(
            point.dx + width * cos(offsetAngle),
            point.dy + width * sin(offsetAngle),
          );
        }
      }
    }
  }
  return path;
}

double _calculateMiterAngle(Offset a, Offset b, Offset c) {
  final ba = b - a;
  final bc = b - c;
  final dotProduct = ba.dx * bc.dx + ba.dy * bc.dy;
  final magnitudeBA = ba.distance;
  final magnitudeBC = bc.distance;
  final cosineAngle = dotProduct / (magnitudeBA * magnitudeBC);
  final clampedCosine = cosineAngle.clamp(-1.0, 1.0);
  return acos(clampedCosine);
}
