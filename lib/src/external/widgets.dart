import 'package:canvas/canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TertiaryPanGestureRecognizer extends PanGestureRecognizer {
  TertiaryPanGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  }) : super(allowedButtonsFilter: (buttons) {
          return buttons == kTertiaryButton;
        });
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
}

extension BoxConstraintsExtension on BoxConstraints {
  Size get biggestAllowNegative {
    double absMinWidth = minWidth.abs();
    double absMinHeight = minHeight.abs();
    double absMaxWidth = maxWidth.abs();
    double absMaxHeight = maxHeight.abs();
    double width = absMinWidth < absMaxWidth ? maxWidth : minWidth;
    double height = absMinHeight < absMaxHeight ? maxHeight : minHeight;
    return Size(width, height);
  }

  bool equalsIgnoreSign(BoxConstraints other) {
    return minWidth == other.minWidth &&
        minHeight == other.minHeight &&
        maxWidth == other.maxWidth &&
        maxHeight == other.maxHeight;
  }
}

class AdaptiveSizedBox extends StatelessWidget {
  final Size size;
  final Widget child;

  const AdaptiveSizedBox({
    super.key,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    double width = size.width;
    double height = size.height;
    if (width.isNaN) {
      width = 0;
    }
    if (height.isNaN) {
      height = 0;
    }
    bool flipHorizontal = width.isNegative;
    bool flipVertical = height.isNegative;
    if (flipHorizontal) {
      width = -width;
    }
    if (flipVertical) {
      height = -height;
    }
    return Transform(
      transform: Matrix4.identity()
        ..scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0),
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class NonOpaqueMetaData extends MetaData {
  const NonOpaqueMetaData({
    super.key,
    required this.opaque,
    super.child,
    super.behavior,
    super.metaData,
  });

  final bool opaque;

  @override
  RenderNonOpaqueMetaData createRenderObject(BuildContext context) {
    return RenderNonOpaqueMetaData(
        opaque: opaque, metaData: metaData, behavior: behavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderNonOpaqueMetaData renderObject) {
    renderObject
      ..opaque = opaque
      ..metaData = metaData
      ..behavior = behavior;
  }
}

class RenderNonOpaqueMetaData extends RenderMetaData {
  bool opaque;
  RenderNonOpaqueMetaData({
    super.metaData,
    super.behavior,
    required this.opaque,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!opaque) {
      super.hitTest(result, position: position);
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

class DecoratedPolygon extends StatelessWidget {
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final Polygon polygon;

  const DecoratedPolygon({
    super.key,
    required this.polygon,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PolygonPainter(
        polygon: polygon,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Polygon polygon;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;

  const PolygonPainter({
    required this.polygon,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
  });

  @override
  bool? hitTest(Offset position) {
    return polygon.contains(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Path? path;
    if (fillColor != null) {
      path ??= polygon.path;
      canvas.drawPath(path, Paint()..color = fillColor!);
    }
    if (strokeColor != null) {
      path ??= polygon.path;
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PolygonPainter oldDelegate) {
    return oldDelegate.polygon != polygon ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class PathClipper extends CustomClipper<Path> {
  final Path path;

  const PathClipper(this.path);

  @override
  Path getClip(Size size) {
    return path;
  }

  @override
  bool shouldReclip(covariant PathClipper oldClipper) {
    return oldClipper.path != path;
  }
}
