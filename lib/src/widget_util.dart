import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

class DecoratedPolygon extends StatelessWidget {
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final List<Offset> polygon;

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
  final List<Offset> polygon;
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
    return path.contains(position);
  }

  Path get path {
    final Path path = Path();
    if (polygon.isNotEmpty) {
      path.moveTo(polygon.first.dx, polygon.first.dy);
      for (int i = 1; i < polygon.length; i++) {
        path.lineTo(polygon[i].dx, polygon[i].dy);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Path? path;
    if (fillColor != null) {
      path ??= this.path;
      canvas.drawPath(path, Paint()..color = fillColor!);
    }
    if (strokeColor != null) {
      path ??= this.path;
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

class TertiaryPanGestureRecognizer extends PanGestureRecognizer {
  TertiaryPanGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  }) : super(allowedButtonsFilter: (buttons) {
          return buttons == kTertiaryButton;
        });
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

class FreeHitClipPath extends SingleChildRenderObjectWidget {
  const FreeHitClipPath({
    super.key,
    required this.clipper,
    this.clipBehavior = Clip.hardEdge,
    super.child,
  });

  final CustomClipper<Path> clipper;
  final Clip clipBehavior;

  @override
  RenderFreeHitClipPath createRenderObject(BuildContext context) {
    return RenderFreeHitClipPath(
      clipper: clipper,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFreeHitClipPath renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }
}

class RenderFreeHitClipPath extends RenderProxyBox {
  RenderFreeHitClipPath({
    required CustomClipper<Path> clipper,
    Clip clipBehavior = Clip.hardEdge,
  })  : _clipper = clipper,
        _clipBehavior = clipBehavior;

  CustomClipper<Path> get clipper => _clipper;
  CustomClipper<Path> _clipper;
  set clipper(CustomClipper<Path> value) {
    if (_clipper == value) {
      return;
    }
    final CustomClipper<Path> oldClipper = _clipper;
    _clipper = value;
    if (value.runtimeType != oldClipper.runtimeType ||
        value.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper.removeListener(_markNeedsClip);
      value.addListener(_markNeedsClip);
    }
  }

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  Clip _clipBehavior;

  Path? _clip;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    _clipper.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void _updateClip() {
    _clip ??= _clipper.getClip(size);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _clip?.getBounds();
    }
  }

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
        layer = context.pushClipPath(
          needsCompositing,
          offset,
          _clip!.getBounds(),
          _clip!,
          super.paint,
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipPathLayer?,
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

class FreeHitOpacity extends SingleChildRenderObjectWidget {
  const FreeHitOpacity({
    super.key,
    required this.opacity,
    super.child,
  });

  final double opacity;

  @override
  RenderFreeHitOpacity createRenderObject(BuildContext context) {
    return RenderFreeHitOpacity(opacity: opacity);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFreeHitOpacity renderObject) {
    renderObject.opacity = opacity;
  }
}

class RenderFreeHitOpacity extends RenderProxyBox {
  RenderFreeHitOpacity(
      {double opacity = 1.0,
      bool alwaysIncludeSemantics = false,
      RenderBox? child})
      : assert(opacity >= 0.0 && opacity <= 1.0),
        _opacity = opacity,
        _alwaysIncludeSemantics = alwaysIncludeSemantics,
        _alpha = ui.Color.getAlphaFromOpacity(opacity),
        super(child);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_alpha == 0) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _alpha > 0;

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  int _alpha;
  double get opacity => _opacity;
  double _opacity;
  set opacity(double value) {
    assert(value >= 0.0 && value <= 1.0);
    if (_opacity == value) {
      return;
    }
    final bool didNeedCompositing = alwaysNeedsCompositing;
    final bool wasVisible = _alpha != 0;
    _opacity = value;
    _alpha = ui.Color.getAlphaFromOpacity(_opacity);
    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsCompositedLayerUpdate();
    if (wasVisible != (_alpha != 0) && !alwaysIncludeSemantics) {
      markNeedsSemanticsUpdate();
    }
  }

  bool get alwaysIncludeSemantics => _alwaysIncludeSemantics;
  bool _alwaysIncludeSemantics;
  set alwaysIncludeSemantics(bool value) {
    if (value == _alwaysIncludeSemantics) {
      return;
    }
    _alwaysIncludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  bool paintsChild(RenderBox child) {
    assert(child.parent == this);
    return _alpha > 0;
  }

  @override
  OffsetLayer updateCompositedLayer(
      {required covariant OpacityLayer? oldLayer}) {
    final OpacityLayer layer = oldLayer ?? OpacityLayer();
    layer.alpha = _alpha;
    return layer;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _alpha == 0) {
      return;
    }
    super.paint(context, offset);
  }
}

class FreeHitIgnorePointer extends SingleChildRenderObjectWidget {
  const FreeHitIgnorePointer({
    super.key,
    required this.ignoring,
    super.child,
  });

  final bool ignoring;

  @override
  RenderFreeHitIgnorePointer createRenderObject(BuildContext context) {
    return RenderFreeHitIgnorePointer(ignoring: ignoring);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFreeHitIgnorePointer renderObject) {
    renderObject.ignoring = ignoring;
  }
}

class RenderFreeHitIgnorePointer extends RenderProxyBox {
  RenderFreeHitIgnorePointer({bool ignoring = false}) : _ignoring = ignoring;

  bool get ignoring => _ignoring;
  bool _ignoring;
  set ignoring(bool value) {
    if (_ignoring == value) {
      return;
    }
    _ignoring = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (ignoring) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
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
  final bool passthrough;
  const GroupWidget({super.key, super.children, this.passthrough = false});

  @override
  RenderGroup createRenderObject(BuildContext context) {
    return RenderGroup(passthrough: passthrough);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGroup renderObject) {
    if (renderObject.passthrough != passthrough) {
      renderObject.passthrough = passthrough;
      renderObject.markNeedsLayout();
    }
  }
}

class GroupParentData extends ContainerBoxParentData<RenderBox> {}

class RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  bool passthrough;

  RenderGroup({required this.passthrough});

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
      child.layout(passthrough ? constraints : const BoxConstraints());
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
