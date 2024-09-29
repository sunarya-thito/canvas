import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

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
}

abstract class Layout {
  const Layout();
  void performLayout(CanvasItem item);
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
  void performLayout(CanvasItem item) {
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
    return AbsoluteLayout(
      offset: offset,
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
}

abstract class CanvasItem {
  ValueNotifier<Layout> layoutNotifier = ValueNotifier(AbsoluteLayout());
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
}

class RootCanvasItem extends CanvasItem {
  RootCanvasItem({
    List<CanvasItem> children = const [],
    required Layout layout,
  }) {
    this.children = children;
    this.layout = layout;
  }
}

class BoxCanvasItem extends CanvasItem {
  final Widget? decoration;
  BoxCanvasItem({
    this.decoration,
    List<CanvasItem> children = const [],
    required Layout layout,
    bool selected = false,
  }) {
    this.children = children;
    this.layout = layout;
    this.selected = selected;
  }

  @override
  Widget? build(BuildContext context) {
    return decoration;
  }
}

abstract class TransformControl {
  const TransformControl();
  Widget build(BuildContext context, CanvasItem node);
}
