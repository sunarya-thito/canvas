import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CanvasParentData extends ContainerBoxParentData<RenderBox> {
  Rect? bounds;
  double? rotation;
  Alignment? anchor;
  bool isGizmo = false;
}

class PositionedCanvasItem extends ParentDataWidget<CanvasParentData> {
  final Rect bounds;
  final double rotation;
  final Alignment anchor;

  const PositionedCanvasItem({
    super.key,
    required this.bounds,
    required this.rotation,
    required this.anchor,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as CanvasParentData;
    bool needsLayout = false;
    if (parentData.bounds != bounds) {
      parentData.bounds = bounds;
      needsLayout = true;
    }
    if (parentData.rotation != rotation) {
      parentData.rotation = rotation;
      needsLayout = true;
    }
    if (parentData.anchor != anchor) {
      parentData.anchor = anchor;
      needsLayout = true;
    }
    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CanvasStackViewport;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('bounds', bounds));
  }
}

class GizmoCanvasItem extends ParentDataWidget<CanvasParentData> {
  const GizmoCanvasItem({
    super.key,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as CanvasParentData;
    if (!parentData.isGizmo) {
      parentData.isGizmo = true;
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isGizmo', true));
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CanvasStackViewport;
}

class CanvasStackViewport extends MultiChildRenderObjectWidget {
  final double scale;
  final Offset offset;
  CanvasStackViewport({
    super.key,
    required List<Widget> children,
    required this.scale,
    required this.offset,
  }) : super(children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCanvasStackViewport(
      scale: scale,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCanvasStackViewport renderObject,
  ) {
    bool needsLayout = false;
    if (renderObject._scale != scale) {
      renderObject._scale = scale;
      needsLayout = true;
    }
    if (renderObject._offset != offset) {
      renderObject._offset = offset;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
  }
}

Offset rotatePoint(Offset point, double rotations, Offset anchor) {
  final cosTheta = cos(rotations);
  final sinTheta = sin(rotations);
  final x = point.dx - anchor.dx;
  final y = point.dy - anchor.dy;
  return Offset(
    x * cosTheta - y * sinTheta + anchor.dx,
    x * sinTheta + y * cosTheta + anchor.dy,
  );
}

Offset _getAnchorOffset(Rect bounds, Alignment anchor) {
  // anchor is -1 to 1, so we need to convert it to 0 to 1
  final anchorX = (anchor.x + 1) / 2;
  final anchorY = (anchor.y + 1) / 2;
  return Offset(
    bounds.topLeft.dx + bounds.width * anchorX,
    bounds.topLeft.dy + bounds.height * anchorY,
  );
}

Rect _computePaintBounds(Rect bounds, double rotation, Alignment anchor) {
  final anchorOffset = _getAnchorOffset(bounds, anchor);
  final topLeft = rotatePoint(bounds.topLeft, rotation, anchorOffset);
  final topRight = rotatePoint(bounds.topRight, rotation, anchorOffset);
  final bottomLeft = rotatePoint(bounds.bottomLeft, rotation, anchorOffset);
  final bottomRight = rotatePoint(bounds.bottomRight, rotation, anchorOffset);
  final minX = min(
    min(topLeft.dx, topRight.dx),
    min(bottomLeft.dx, bottomRight.dx),
  );
  final maxX = max(
    max(topLeft.dx, topRight.dx),
    max(bottomLeft.dx, bottomRight.dx),
  );
  final minY = min(
    min(topLeft.dy, topRight.dy),
    min(bottomLeft.dy, bottomRight.dy),
  );
  final maxY = max(
    max(topLeft.dy, topRight.dy),
    max(bottomLeft.dy, bottomRight.dy),
  );
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

Rect computeCanvasItemBounds(CanvasItemTransform transform,
    {Alignment anchor = Alignment.center}) {
  return _computePaintBounds(
    transform.position & transform.size,
    transform.rotation,
    anchor,
  );
}

class RenderCanvasStackViewport extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, CanvasParentData> {
  double _scale;
  Offset _offset;

  RenderCanvasStackViewport({
    List<RenderBox>? children,
    double scale = 1.0,
    Offset offset = Offset.zero,
  })  : _scale = scale,
        _offset = offset {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CanvasParentData) {
      child.parentData = CanvasParentData();
    }
  }

  Rect _adjustBounds(Rect bounds, double scale, Offset offset) {
    return Rect.fromLTWH(
      bounds.left * scale + offset.dx,
      bounds.top * scale + offset.dy,
      bounds.width * scale,
      bounds.height * scale,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      // The x, y parameters have the top left of the node's box as the origin.
      final childParentData = child.parentData as CanvasParentData;
      if (!childParentData.isGizmo) {
        child = childParentData.previousSibling;
        continue;
      }
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as CanvasParentData;
      if (childParentData.isGizmo) {
        child.layout(BoxConstraints.tight(size));
        child = childParentData.nextSibling;
        continue;
      }
      var bounds = childParentData.bounds;
      assert(bounds != null, 'Canvas item bounds must not be null');
      bounds = _adjustBounds(bounds!, _scale, _offset);
      final paintBounds = _computePaintBounds(
          bounds, childParentData.rotation!, childParentData.anchor!);
      if (!paintBounds.overlaps(Offset.zero & size)) {
        child = childParentData.nextSibling;
        continue;
      }
      child.layout(BoxConstraints.tight(bounds.size));
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as CanvasParentData;
      if (childParentData.isGizmo) {
        context.paintChild(child, offset + childParentData.offset);
        child = childParentData.nextSibling;
        continue;
      }
      final bounds = childParentData.bounds;
      assert(bounds != null, 'Canvas item bounds must not be null');
      final paintBounds = _computePaintBounds(
          bounds!, childParentData.rotation!, childParentData.anchor!);
      if (!paintBounds.overlaps(Offset.zero & size)) {
        child = childParentData.nextSibling;
        continue;
      }

      context.paintChild(child, offset + bounds.topLeft * _scale + _offset);
      // paint at center
      final canvas = context.canvas;
      // paint white dot
      canvas.drawCircle(
        offset + bounds.center * _scale + _offset,
        5,
        Paint()..color = Colors.white,
      );
      child = childParentData.nextSibling;
    }
  }
}
