import 'package:flutter/rendering.dart';

class RenderConstrainedCanvasItem extends RenderProxyBox {
  Size _transform;

  RenderConstrainedCanvasItem({
    required Size transform,
    RenderBox? child,
  })  : _transform = transform,
        super(child);

  set transform(Size value) {
    if (_transform == value) return;
    _transform = value;
    markNeedsLayout();
  }

  Size get transform => _transform;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double flipX = _transform.width < 0 ? -1 : 1;
    double flipY = _transform.height < 0 ? -1 : 1;
    if (flipX < 0 || flipY < 0) {
      context.pushTransform(
        needsCompositing,
        offset,
        Matrix4.identity()..scale(flipX, flipY),
        (context, offset) {
          super.paint(context, offset);
        },
      );
    } else {
      super.paint(context, offset);
    }
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(BoxConstraints.loose(Size(
      _transform.width.abs(),
      _transform.height.abs(),
    )));
    size = Size.zero;
  }
}

class RenderCanvasGroup extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, StackParentData> {
  Clip _clipBehavior;
  RenderCanvasGroup({
    required Clip clipBehavior,
    List<RenderBox>? children,
  })  : _clipBehavior = clipBehavior,
        super() {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  set clipBehavior(Clip value) {
    if (_clipBehavior == value) return;
    _clipBehavior = value;
    markNeedsLayout();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as StackParentData;
      final childHit = child.hitTest(result, position: position);
      if (childHit) return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  void paintStack(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as StackParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_clipBehavior != Clip.none) {
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) {
          paintStack(context, offset);
        },
        clipBehavior: _clipBehavior,
        oldLayer: null,
      );
    } else {
      paintStack(context, offset);
    }
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as StackParentData;
      child.layout(const BoxConstraints());
      child = childParentData.nextSibling;
    }
    size = constraints.biggest.isInfinite ? Size.zero : constraints.biggest;
  }
}
