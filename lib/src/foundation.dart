import 'package:canvas/src/util.dart';
import 'package:canvas/src/widgets.dart';
import 'package:flutter/widgets.dart';

class SnappingConfiguration {
  static const List<double> defaultSnappingAngles = [
    0,
    45,
    90,
    135,
    180,
    225,
    270,
    315,
  ];
  final bool enableObjectSnapping;
  final bool enableRotationSnapping;
  final double threshold;
  final List<double> angles;

  const SnappingConfiguration({
    this.enableObjectSnapping = true,
    this.enableRotationSnapping = true,
    this.threshold = 10,
    this.angles = defaultSnappingAngles,
  });

  double snapAngle(double angle) {
    double minDiff = double.infinity;
    double result = angle;
    for (final snappingAngle in angles) {
      double diff = (angle - snappingAngle).abs();
      if (diff < minDiff) {
        minDiff = diff;
        result = snappingAngle;
      }
    }
    return result;
  }
}

class SnappingPoint {
  final Offset position;
  final double angle;

  SnappingPoint({
    required this.position,
    required this.angle,
  });

  Offset? snap(SnappingPoint other, SnappingConfiguration config) {
    return null;
  }
}

typedef Snapper = Offset? Function(SnappingPoint snappingPoint);

class ReparentDetails {
  final CanvasItem item;
  final CanvasItem? oldParent;
  final CanvasItem? newParent;

  ReparentDetails({
    required this.item,
    this.oldParent,
    this.newParent,
  });
}

class LayoutTransform {
  final Offset offset;
  final double rotation;
  final Offset scale;
  final Size size;

  LayoutTransform({
    this.offset = Offset.zero,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
    this.size = Size.zero,
  });

  Size get scaledSize => Size(size.width * scale.dx, size.height * scale.dy);

  Offset transformFromParent(Offset offset) {
    offset = offset - this.offset;
    offset = rotatePoint(offset, -rotation);
    return offset;
  }

  Offset transformToParent(Offset offset) {
    offset = rotatePoint(offset, rotation);
    offset = offset + this.offset;
    return offset;
  }

  LayoutTransform copyWith({
    Offset? offset,
    double? rotation,
    Offset? scale,
    Size? size,
  }) {
    return LayoutTransform(
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      size: size ?? this.size,
    );
  }

  LayoutTransform operator *(LayoutTransform other) {
    return LayoutTransform(
      offset: offset + other.offset,
      rotation: rotation + other.rotation,
      scale: scale,
      size: size,
    );
  }

  @override
  String toString() {
    return 'LayoutTransform(offset: $offset, rotation: $rotation, scale: $scale, size: $size)';
  }
}

abstract class Layout {
  const Layout();
  void performLayout(CanvasItem item, [CanvasItem? parent]);
  void performSelfLayout(CanvasItem item);
  Layout drag(Offset delta);
  Layout rotate(double delta, [Alignment alignment = Alignment.center]);
  Layout resizeTopLeft(Offset delta,
      {bool proportional = false, bool symmetric = false});
  Layout resizeTopRight(Offset delta,
      {bool proportional = false, bool symmetric = false});
  Layout resizeBottomLeft(Offset delta,
      {bool proportional = false, bool symmetric = false});
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false, bool symmetric = false});
  Layout resizeTop(Offset delta, {bool symmetric = false});
  Layout resizeLeft(Offset delta, {bool symmetric = false});
  Layout resizeRight(Offset delta, {bool symmetric = false});
  Layout resizeBottom(Offset delta, {bool symmetric = false});
  Layout rescaleTopLeft(Offset delta,
      {bool symmetric = false, bool proportional = false});
  Layout rescaleTopRight(Offset delta,
      {bool symmetric = false, bool proportional = false});
  Layout rescaleBottomLeft(Offset delta,
      {bool symmetric = false, bool proportional = false});
  Layout rescaleBottomRight(Offset delta,
      {bool symmetric = false, bool proportional = false});
  Layout rescaleTop(Offset delta, {bool symmetric = false});
  Layout rescaleLeft(Offset delta, {bool symmetric = false});
  Layout rescaleRight(Offset delta, {bool symmetric = false});
  Layout rescaleBottom(Offset delta, {bool symmetric = false});
  bool get shouldHandleChildLayout;
}

class AbsoluteLayout extends Layout {
  final Offset offset;
  final Size size;
  final double rotation;
  final Offset scale;

  const AbsoluteLayout({
    this.offset = Offset.zero,
    this.size = Size.zero,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  });

  Size get scaledSize => Size(size.width * scale.dx, size.height * scale.dy);

  double get aspectRatio {
    Size scaledSize = this.scaledSize;
    return scaledSize.width / scaledSize.height;
  }

  @override
  void performLayout(CanvasItem item, [CanvasItem? parent]) {
    if (parent != null && parent.layout.shouldHandleChildLayout) {
      parent.layoutNotifier.value.performLayout(parent);
      return;
    }
    performSelfLayout(item);
  }

  @override
  void performSelfLayout(CanvasItem item) {
    item.transform = LayoutTransform(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  Layout drag(Offset delta) {
    return AbsoluteLayout(
      offset: offset + delta,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  Layout rotate(double delta, [Alignment alignment = Alignment.center]) {
    Size scaledSize = this.scaledSize;
    Offset before = rotatePoint(-alignment.alongSize(scaledSize), rotation);
    Offset after =
        rotatePoint(-alignment.alongSize(scaledSize), rotation + delta);
    Offset offsetDelta = after - before;
    return AbsoluteLayout(
      offset: offset + offsetDelta,
      size: size,
      rotation: rotation + delta,
      scale: scale,
    );
  }

  @override
  Layout resizeBottom(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.divideBy(scale);
    Layout result = AbsoluteLayout(
      offset: offset,
      size: Size(size.width, size.height + delta.dy),
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeTop(-originalDelta);
    }
    return result;
  }

  @override
  Layout resizeBottomLeft(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeBottom(delta).resizeLeft(delta);
    if (symmetric) {
      result = result.resizeTopRight(-delta);
    }
    return result;
  }

  @override
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeBottom(delta).resizeRight(delta);
    if (symmetric) {
      result = result.resizeTopLeft(-delta);
    }
    return result;
  }

  @override
  Layout resizeLeft(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    delta = delta.divideBy(scale);
    Layout result = AbsoluteLayout(
      offset: offset + rotatedDelta,
      size: Size(size.width - delta.dx, size.height),
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeRight(-originalDelta);
    }
    return result;
  }

  @override
  Layout resizeRight(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    delta = delta.divideBy(scale);
    Layout result = AbsoluteLayout(
      offset: offset,
      size: Size(size.width + delta.dx, size.height),
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeLeft(-originalDelta);
    }
    return result;
  }

  @override
  Layout resizeTop(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    delta = delta.divideBy(scale);
    Layout result = AbsoluteLayout(
      offset: offset + rotatedDelta,
      size: Size(size.width, size.height - delta.dy),
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeBottom(-originalDelta);
    }
    return result;
  }

  @override
  Layout resizeTopLeft(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeTop(delta).resizeLeft(delta);
    if (symmetric) {
      result = result.resizeBottomRight(-delta);
    }
    return result;
  }

  @override
  Layout resizeTopRight(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeTop(delta).resizeRight(delta);
    if (symmetric) {
      result = result.resizeBottomLeft(-delta);
    }
    return result;
  }

  @override
  Layout rescaleBottom(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: Offset(scale.dx, scale.dy + delta.dy / size.height),
    );
    if (symmetric) {
      result = result.rescaleTop(-originalDelta);
    }
    return result;
  }

  @override
  Layout rescaleBottomLeft(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleBottom(delta).rescaleLeft(delta);
    if (symmetric) {
      result = result.rescaleTopRight(-delta);
    }
    return result;
  }

  @override
  Layout rescaleBottomRight(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleBottom(delta).rescaleRight(delta);
    if (symmetric) {
      result = result.rescaleTopLeft(-delta);
    }
    return result;
  }

  @override
  Layout rescaleLeft(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    Layout result = AbsoluteLayout(
      offset: offset + rotatedDelta,
      size: size,
      rotation: rotation,
      scale: Offset(scale.dx - delta.dx / size.width, scale.dy),
    );
    if (symmetric) {
      result = result.rescaleRight(-originalDelta);
    }
    return result;
  }

  @override
  Layout rescaleRight(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: Offset(scale.dx + delta.dx / size.width, scale.dy),
    );
    if (symmetric) {
      result = result.rescaleLeft(-originalDelta);
    }
    return result;
  }

  @override
  Layout rescaleTop(Offset delta, {bool symmetric = false}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    Layout result = AbsoluteLayout(
      offset: offset + rotatedDelta,
      size: size,
      rotation: rotation,
      scale: Offset(scale.dx, scale.dy - delta.dy / size.height),
    );
    if (symmetric) {
      result = result.rescaleBottom(-originalDelta);
    }
    return result;
  }

  @override
  Layout rescaleTopLeft(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleTop(delta).rescaleLeft(delta);
    if (symmetric) {
      result = result.rescaleBottomRight(-delta);
    }
    return result;
  }

  @override
  Layout rescaleTopRight(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleTop(delta).rescaleRight(delta);
    if (symmetric) {
      result = result.rescaleBottomLeft(-delta);
    }
    return result;
  }

  @override
  bool get shouldHandleChildLayout => false;
}

abstract class CanvasItem {
  ValueNotifier<Layout> layoutNotifier = ValueNotifier(const AbsoluteLayout());
  ValueNotifier<LayoutTransform> transformNotifier =
      ValueNotifier(LayoutTransform());
  ValueNotifier<List<CanvasItem>> childrenNotifier = ValueNotifier([]);
  ValueNotifier<bool> selectedNotifier = ValueNotifier(false);

  Widget? build(BuildContext context) => null;

  Layout get layout => layoutNotifier.value;
  List<CanvasItem> get children => childrenNotifier.value;
  LayoutTransform get transform => transformNotifier.value;
  bool get selected => selectedNotifier.value;

  set layout(Layout layout) => layoutNotifier.value = layout;
  set children(List<CanvasItem> children) => childrenNotifier.value = children;
  set transform(LayoutTransform transform) =>
      transformNotifier.value = transform;
  set selected(bool selected) => selectedNotifier.value = selected;

  void visit(void Function(CanvasItem item) visitor) {
    visitor(this);
    for (final child in children) {
      child.visit(visitor);
    }
  }

  void visitWithTransform(
      void Function(CanvasItem item, LayoutTransform? parentTransform) visitor,
      {bool rootSelectionOnly = false,
      LayoutTransform? parentTransform}) {
    final transform = parentTransform == null
        ? this.transform
        : parentTransform * this.transform;
    visitor(this, parentTransform);
    if (rootSelectionOnly && selected) {
      return;
    }
    for (final child in children) {
      child.visitWithTransform(visitor,
          parentTransform: transform, rootSelectionOnly: rootSelectionOnly);
    }
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    var transform = this.transform;
    position = position - transform.offset;
    position = rotatePoint(position, -transform.rotation);
    hitTestSelf(result, position);
    hitTestChildren(result, position);
  }

  void hitTestSelf(CanvasHitTestResult result, Offset position);

  void hitTestChildren(CanvasHitTestResult result, Offset position) {
    for (final child in children) {
      child.hitTest(result, position);
    }
  }

  CanvasItemNode toNode([CanvasItemNode? parent]) {
    return CanvasItemNode(parent, this);
  }

  void visitSnappingPoints(void Function(SnappingPoint snappingPoint) visitor,
      [LayoutTransform? parentTransform]) {
    var currentTransform =
        parentTransform == null ? transform : parentTransform * transform;
    var scaledSize = currentTransform.scaledSize;
    Offset topLeft = currentTransform.offset;
    Offset topRight = currentTransform.offset +
        rotatePoint(Offset(scaledSize.width, 0), currentTransform.rotation);
    Offset bottomLeft = currentTransform.offset +
        rotatePoint(Offset(0, scaledSize.height), currentTransform.rotation);
    Offset bottomRight = currentTransform.offset +
        rotatePoint(Offset(scaledSize.width, scaledSize.height),
            currentTransform.rotation);
    Offset center = currentTransform.offset +
        rotatePoint(Offset(scaledSize.width / 2, scaledSize.height / 2),
            currentTransform.rotation);
    visitor(SnappingPoint(position: topLeft, angle: currentTransform.rotation));
    visitor(
        SnappingPoint(position: topRight, angle: currentTransform.rotation));
    visitor(
        SnappingPoint(position: bottomLeft, angle: currentTransform.rotation));
    visitor(
        SnappingPoint(position: bottomRight, angle: currentTransform.rotation));
    visitor(SnappingPoint(position: center, angle: currentTransform.rotation));
    for (final child in children) {
      child.visitSnappingPoints(visitor, currentTransform);
    }
  }
}

class RootCanvasItem extends CanvasItem {
  RootCanvasItem({
    List<CanvasItem> children = const [],
    required Layout layout,
  }) {
    this.children = children;
    this.layout = layout;
  }

  @override
  void hitTestSelf(CanvasHitTestResult result, Offset position) {}
}

class BoxCanvasItem extends CanvasItem {
  final Widget? decoration;
  final String? debugLabel;
  BoxCanvasItem({
    this.decoration,
    List<CanvasItem> children = const [],
    required Layout layout,
    bool selected = false,
    this.debugLabel,
  }) {
    this.children = children;
    this.layout = layout;
    this.selected = selected;
  }

  @override
  void hitTestSelf(CanvasHitTestResult result, Offset position) {
    var scaledSize = transform.scaledSize;
    if (position.dx >= 0 &&
        position.dx <= scaledSize.width &&
        position.dy >= 0 &&
        position.dy <= scaledSize.height) {
      result.path.add(CanvasHitTestEntry(this, position));
    }
  }

  @override
  Widget? build(BuildContext context) {
    return decoration;
  }

  @override
  String toString() {
    return 'BoxCanvasItem($debugLabel)';
  }
}

abstract class TransformControl {
  const TransformControl();
  Widget build(BuildContext context, CanvasItem node);
}
