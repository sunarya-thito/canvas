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

  Size get smallestAllowNegative {
    double absMinWidth = minWidth.abs();
    double absMinHeight = minHeight.abs();
    double absMaxWidth = maxWidth.abs();
    double absMaxHeight = maxHeight.abs();
    double width = absMinWidth < absMaxWidth ? minWidth : maxWidth;
    double height = absMinHeight < absMaxHeight ? minHeight : maxHeight;
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
      child: FreeHitSizedBox(
        size: Size(width, height),
        child: child,
      ),
    );
  }
}

class FreeHitSizedBox extends SingleChildRenderObjectWidget {
  const FreeHitSizedBox({
    super.key,
    required this.size,
    super.child,
  });

  final Size size;

  @override
  RenderFreeHitSizedBox createRenderObject(BuildContext context) {
    return RenderFreeHitSizedBox(
      additionalConstraints: BoxConstraints.tight(size),
    );
  }

  @override
  RenderFreeHitSizedBox updateRenderObject(
      BuildContext context, covariant RenderFreeHitSizedBox renderObject) {
    return renderObject..additionalConstraints = BoxConstraints.tight(size);
  }
}

class RenderFreeHitSizedBox extends RenderConstrainedBox {
  RenderFreeHitSizedBox({required super.additionalConstraints});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

class RRectClipper extends CustomClipper<RRect> {
  final BorderRadiusGeometry borderRadius;
  final TextDirection? textDirection;

  const RRectClipper({
    required this.borderRadius,
    this.textDirection,
  });

  @override
  RRect getClip(Size size) {
    return borderRadius.resolve(textDirection).toRRect(Offset.zero & size);
  }

  @override
  bool shouldReclip(covariant RRectClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.textDirection != textDirection;
  }
}

class FreeHitClipRRect extends SingleChildRenderObjectWidget {
  const FreeHitClipRRect({
    super.key,
    required this.borderRadius,
    this.clipBehavior = Clip.hardEdge,
    this.clipper,
    super.child,
  });

  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final CustomClipper<RRect>? clipper;

  @override
  RenderFreeHitClipRRect createRenderObject(BuildContext context) {
    return RenderFreeHitClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      textDirection: Directionality.maybeOf(context),
      clipper: clipper,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFreeHitClipRRect renderObject) {
    renderObject.borderRadius = borderRadius;
    renderObject.clipBehavior = clipBehavior;
    renderObject.textDirection = Directionality.maybeOf(context);
    renderObject.clipper = clipper;
  }
}

class RenderFreeHitClipRRect extends RenderProxyBox {
  RenderFreeHitClipRRect({
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.hardEdge,
    TextDirection? textDirection,
    CustomClipper<RRect>? clipper,
  })  : _borderRadius = borderRadius,
        _textDirection = textDirection,
        _clipBehavior = clipBehavior,
        _clipper = clipper;

  CustomClipper<RRect>? get clipper => _clipper;
  CustomClipper<RRect>? _clipper;
  set clipper(CustomClipper<RRect>? newClipper) {
    if (_clipper == newClipper) {
      return;
    }
    final CustomClipper<RRect>? oldClipper = _clipper;
    _clipper = newClipper;
    assert(newClipper != null || oldClipper != null);
    if (newClipper == null ||
        oldClipper == null ||
        newClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper?.removeListener(_markNeedsClip);
      newClipper?.addListener(_markNeedsClip);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    _clipper?.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  RRect? _clip;

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  Clip _clipBehavior;

  @override
  void performLayout() {
    final Size? oldSize = hasSize ? size : null;
    super.performLayout();
    if (oldSize != size) {
      _clip = null;
    }
  }

  void _updateClip() {
    _clip ??= _clipper?.getClip(size) ?? _defaultClip;
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _clipper?.getApproximateClipRect(size) ?? Offset.zero & size;
    }
  }

  BorderRadiusGeometry get borderRadius => _borderRadius;
  BorderRadiusGeometry _borderRadius;
  set borderRadius(BorderRadiusGeometry value) {
    if (_borderRadius == value) {
      return;
    }
    _borderRadius = value;
    _markNeedsClip();
  }

  /// The text direction with which to resolve [borderRadius].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedsClip();
  }

  RRect get _defaultClip =>
      _borderRadius.resolve(textDirection).toRRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    _updateClip();
    assert(_clip != null);
    if (clipBehavior != Clip.none && !_clip!.contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      if (clipBehavior != Clip.none) {
        _updateClip();
        layer = context.pushClipRRect(
          needsCompositing,
          offset,
          _clip!.outerRect,
          _clip!,
          super.paint,
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipRRectLayer?,
        );
      } else {
        context.paintChild(child!, offset);
        layer = null;
      }
    } else {
      layer = null;
    }
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

class GroupWidget extends MultiChildRenderObjectWidget {
  const GroupWidget({super.key, super.children});

  @override
  RenderGroup createRenderObject(BuildContext context) {
    return RenderGroup();
  }
}

class GroupParentData extends ContainerBoxParentData<RenderBox> {}

class RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      final GroupParentData childParentData =
          child.parentData as GroupParentData;
      child.layout(const BoxConstraints());
      child = childParentData.nextSibling;
    }

    size = constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
