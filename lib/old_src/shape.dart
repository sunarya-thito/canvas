import 'dart:math';

import 'package:flutter/widgets.dart';

class FrameDecoration extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    // TODO: implement createBoxPainter
    throw UnimplementedError();
  }
}

class FramePainter extends BoxPainter {
  FramePainter(super.onChanged);
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {}
}

abstract class FrameLayer {
  const FrameLayer();
  FrameLayerPainter createPainter();
}

abstract class FrameLayerPainter {
  const FrameLayerPainter();
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration,
      Path path);
  void dispose() {}
}

class FrameColorFillLayer extends FrameLayer {
  final Color color;
  const FrameColorFillLayer(this.color);

  @override
  FrameLayerPainter createPainter() {
    return FrameColorFillLayerPainter(color);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrameColorFillLayer && other.color == color;
  }

  @override
  int get hashCode => color.hashCode;
}

class FrameColorFillLayerPainter extends FrameLayerPainter {
  final Color color;
  const FrameColorFillLayerPainter(this.color);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration,
      Path path) {
    canvas.drawPath(path, Paint()..color = color);
  }
}

class FrameBorderLayer extends FrameLayer {
  final Border border;
  const FrameBorderLayer(this.border);

  @override
  FrameLayerPainter createPainter() {
    return FrameBorderLayerPainter(border);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrameBorderLayer && other.border == border;
  }

  @override
  int get hashCode => border.hashCode;
}

class FrameBorderLayerPainter extends FrameLayerPainter {
  final Border border;
  const FrameBorderLayerPainter(this.border);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration,
      Path path) {
    canvas.drawPath(path, Paint()..color = border.top.color);
  }
}

abstract class Sloppiness {
  static const Sloppiness architect = _SimpleSloppiness(0, 0);
  static const Sloppiness artist = _SimpleSloppiness(2, 0.25);
  static const Sloppiness cartoonist = _SimpleSloppiness(2, 0.125);
  static List<Sloppiness> get values => [
        architect,
        artist,
        cartoonist,
      ];
  Path retrace(Path path, int seed);
}

class _SimpleSloppiness implements Sloppiness {
  final double sloppiness;
  final double frequency;
  const _SimpleSloppiness(this.sloppiness, this.frequency);

  @override
  Path retrace(Path path, int seed) {
    if (sloppiness <= 0) {
      return path;
    }
    var newPath = Path();
    var alternatePath = Path();

    for (var metric in path.computeMetrics()) {
      var extractPath = metric.extractPath(0, metric.length);
      extractPath.computeMetrics().forEach((subMetric) {
        Offset? previousPoint;
        double frequencyLength = frequency * subMetric.length;
        for (double t = 0; t < subMetric.length; t += 1) {
          var point = subMetric.getTangentForOffset(t)!.position;
          var frequencyIndex = (t / frequencyLength).floor();
          var currentFrequencyOffset = t - frequencyIndex * frequencyLength;
          var frequencyCenter = frequencyLength / 2;
          var distanceFromCenter =
              (currentFrequencyOffset - frequencyCenter).abs() /
                  frequencyCenter;
          var random = Random(seed + frequencyIndex);
          var randomX = random.nextDouble();
          var randomY = random.nextDouble();
          var alternateRandomX = randomX * 0.25;
          var alternateRandomY = randomY * 0.25;
          var randomAmount = Offset(
            (randomX - 0.5) * 2,
            (randomY - 0.5) * 2,
          );
          var alternateRandomAmount = Offset(
            (alternateRandomX - 0.5) * 2,
            (alternateRandomY - 0.5) * 2,
          );
          var newPoint =
              point + randomAmount * sloppiness * (1 - distanceFromCenter);
          var alternatePoint = point +
              alternateRandomAmount * sloppiness * (1 - distanceFromCenter);
          if (previousPoint == null) {
            newPath.moveTo(newPoint.dx, newPoint.dy);
            alternatePath.moveTo(alternatePoint.dx, alternatePoint.dy);
          } else {
            newPath.lineTo(newPoint.dx, newPoint.dy);
            alternatePath.lineTo(alternatePoint.dx, alternatePoint.dy);
          }
          previousPoint = point;
        }
      });
    }
    return Path()
      ..addPath(newPath, Offset.zero)
      ..addPath(alternatePath, Offset.zero);
  }
}

class LineType {
  final List<double> dashArray;
  const LineType(this.dashArray);
  static const LineType solid = LineType([1]);
  static const LineType dashed = LineType([3, 3]);
  static const LineType dotted = LineType([1, 1.5]);
}

class FrameBorder {
  final FrameBorderSide top;
  final FrameBorderSide left;
  final FrameBorderSide right;
  final FrameBorderSide bottom;
  const FrameBorder({
    this.top = const FrameBorderSide(),
    this.left = const FrameBorderSide(),
    this.right = const FrameBorderSide(),
    this.bottom = const FrameBorderSide(),
  });

  const FrameBorder.all(
    FrameBorderSide side,
  ) : this(
          top: side,
          left: side,
          right: side,
          bottom: side,
        );

  const FrameBorder.symmetric({
    FrameBorderSide vertical = const FrameBorderSide(),
    FrameBorderSide horizontal = const FrameBorderSide(),
  }) : this(
          top: horizontal,
          left: vertical,
          right: vertical,
          bottom: horizontal,
        );

  FrameBorder copyWith({
    FrameBorderSide? top,
    FrameBorderSide? left,
    FrameBorderSide? right,
    FrameBorderSide? bottom,
  }) {
    return FrameBorder(
      top: top ?? this.top,
      left: left ?? this.left,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}

class FrameBorderSide {
  final Color color;
  final double width;
  final LineType lineType;
  final double align;
  const FrameBorderSide({
    this.color = const Color(0xFF000000),
    this.width = 1.0,
    this.lineType = LineType.solid,
    this.align = 1, // -1 = outside, 0 = center, 1 = inside, (align * width)
  });
}

void paintPath(Path path, Canvas canvas, Size size, FrameBorder border) {
  final paint = Paint();
  var pathMetrics = path.computeMetrics();
  var center = Offset(size.width / 2, size.height / 2);
  Path newPath = Path();
  for (var pathMetric in pathMetrics) {
    // var length = pathMetric.length;
    // var distance = 0.0;
    // while (distance < length) {
    //   var tangent = pathMetric.getTangentForOffset(distance)!;
    //   var point = tangent.position;
    //   var diff = center - point;
    //   var angle = diff.direction;
    //   var degree = (angle * 180 / pi + 90) % 360;
    //   FrameBorderSide side;
    //   if (degree >= 45 && degree < 135) {
    //     side = border.top;
    //   } else if (degree >= 135 && degree < 225) {
    //     side = border.right;
    //   } else if (degree >= 225 && degree < 315) {
    //     side = border.bottom;
    //   } else {
    //     side = border.left;
    //   }
    //   var borderWidth = side.width;
    //   var borderAlign = side.align; // -1 = outside, 0 = center, 1 = inside
    //   var outerOffset = borderAlign * borderWidth + side.width / 2;
    //   var innerOffset = -borderAlign * borderWidth - side.width / 2;
    //   var dashLength = side.lineType.dashArray[0] * borderWidth;
    //   if (distance + dashLength > length) {
    //     dashLength = length - distance;
    //   }
    //   if (side.lineType.dashArray.length > 1) {
    //     if (distance %
    //             (side.lineType.dashArray[0] + side.lineType.dashArray[1]) <
    //         side.lineType.dashArray[0]) {
    //       var end = distance + dashLength;
    //       while (distance < end) {
    //         var tangent = pathMetric.getTangentForOffset(distance)!;
    //         var point = tangent.position;
    //         var diff = center - point;
    //         var angle = diff.direction;
    //       }
    //     }
    //   } else {
    //     var outerPoint =
    //         point + Offset.fromDirection(angle, outerOffset + side.width / 2);
    //     var innerPoint =
    //         point + Offset.fromDirection(angle, innerOffset - side.width / 2);
    //     newPath.moveTo(outerPoint.dx, outerPoint.dy);
    //     newPath.lineTo(innerPoint.dx, innerPoint.dy);
    //     paint.strokeJoin
    //   }
    // }
    // Path combinedPath = Path.combine(
    //   PathOperation.difference,
    //   outerPath,
    //   innerPath,
    // );
    // Path topPath = Path()
    //   ..moveTo(0, 0)
    //   ..lineTo(size.width, 0)
    //   ..lineTo(size.width / 2, size.height / 2)
    //   ..lineTo(0, 0)
    //   ..close();
    // Path leftPath = Path()
    //   ..moveTo(0, 0)
    //   ..lineTo(0, size.height)
    //   ..lineTo(size.width / 2, size.height / 2)
    //   ..lineTo(0, 0)
    //   ..close();
    // Path rightPath = Path()
    //   ..moveTo(size.width, 0)
    //   ..lineTo(size.width, size.height)
    //   ..lineTo(size.width / 2, size.height / 2)
    //   ..lineTo(size.width, 0)
    //   ..close();
    // Path bottomPath = Path()
    //   ..moveTo(0, size.height)
    //   ..lineTo(size.width, size.height)
    //   ..lineTo(size.width / 2, size.height / 2)
    //   ..lineTo(0, size.height)
    //   ..close();
    // Path combinedTopPath = Path.combine(
    //   PathOperation.difference,
    //   topPath,
    //   combinedPath,
    // );
    // Path combinedLeftPath = Path.combine(
    //   PathOperation.difference,
    //   leftPath,
    //   combinedPath,
    // );
    // Path combinedRightPath = Path.combine(
    //   PathOperation.difference,
    //   rightPath,
    //   combinedPath,
    // );
    // Path combinedBottomPath = Path.combine(
    //   PathOperation.difference,
    //   bottomPath,
    //   combinedPath,
    // );
    // canvas.drawPath(combinedPath, paint..color = border.top.color);
    // canvas.drawPath(combinedLeftPath, paint..color = border.left.color);
    // canvas.drawPath(combinedRightPath, paint..color = border.right.color);
    // canvas.drawPath(combinedBottomPath, paint..color = border.bottom.color);
  }
}
