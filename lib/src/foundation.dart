import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../canvas.dart';

abstract class CanvasParent {
  void addChildren(List<CanvasItem> children);
  void removeChildren(List<CanvasItem> children);
  void addChild(CanvasItem child);
  void removeChild(CanvasItem child);
  void removeChildAt(int index);
  void insertChild(int index, CanvasItem child);
  List<CanvasItem> get children;
  ValueListenable<List<CanvasItem>> get childListenable;
}

enum SelectionBehavior {
  intersect,
  contain,
}

abstract class CanvasSelectionHandler {
  CanvasSelectionSession onSelectionStart(
      CanvasViewportHandle handle, CanvasSelectSession session);
  void onInstantSelection(CanvasViewportHandle handle, Offset position);
  bool get shouldCancelObjectDragging;
}

abstract class CanvasSelectionSession {
  void onSelectionChange(CanvasSelectSession session, Offset totalDelta);
  void onSelectionEnd(CanvasSelectSession session);
  void onSelectionCancel();
}

abstract class CanvasViewportHandle {
  CanvasTransform get transform;
  Size get size;
  set transform(CanvasTransform transform);
  void drag(Offset delta);
  void zoomAt(Offset position, double delta);
  Offset get canvasOffset;
  void startSelectSession(Offset position);
  void updateSelectSession(Offset delta);
  void endSelectSession();
  void cancelSelectSession();
  void instantSelection(Offset position);
  bool get enableInstantSelection;
  bool get symmetricResize;
  bool get proportionalResize;
  SnappingConfiguration get snappingConfiguration;
  CanvasController get controller;
  LayoutSnapping createLayoutSnapping(CanvasItemNode node,
      [bool fillInSnappingPoints = true]);
}

class CanvasSelectSession {
  final Offset startPosition;
  final Offset endPosition;

  CanvasSelectSession({
    required this.startPosition,
    required this.endPosition,
  });

  CanvasSelectSession copyWith({
    Offset? startPosition,
    Offset? endPosition,
  }) {
    return CanvasSelectSession(
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
    );
  }
}

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
    360,
  ];
  final bool enableObjectSnapping;
  final bool enableRotationSnapping;
  final double threshold;
  final List<double> angles;
  final Offset? gridSnapping;

  const SnappingConfiguration({
    this.enableObjectSnapping = true,
    this.enableRotationSnapping = true,
    this.threshold = 5,
    this.angles = defaultSnappingAngles,
    this.gridSnapping,
  });

  Offset snapToGrid(Offset offset) {
    if (gridSnapping == null) {
      return offset;
    }
    return Offset(
      (offset.dx / gridSnapping!.dx).round() * gridSnapping!.dx,
      (offset.dy / gridSnapping!.dy).round() * gridSnapping!.dy,
    );
  }

  Size snapToGridSize(Size size) {
    if (gridSnapping == null ||
        gridSnapping!.dx == 0 ||
        gridSnapping!.dy == 0) {
      return size;
    }
    return Size(
      (size.width / gridSnapping!.dx).round() * gridSnapping!.dx,
      (size.height / gridSnapping!.dy).round() * gridSnapping!.dy,
    );
  }

  double snapAngle(double angle) {
    if (!enableRotationSnapping) {
      return angle;
    }
    angle = radToDeg(angle);
    angle = limitDegrees(angle);
    for (final snappingAngle in angles) {
      double diff = (angle - snappingAngle).abs();
      if (diff < threshold) {
        return degToRad(snappingAngle);
      }
    }
    return degToRad(angle);
  }
}

class SnappingPoint {
  final Offset position;
  final double angle;
  final Axis axis;

  SnappingPoint({
    required this.position,
    required this.angle,
    required this.axis,
  });

  Offset? distanceTo(SnappingPoint other) {
    if (other.angle != angle || other.axis != axis) {
      return null;
    }
    Offset otherPosition = other.position;
    // rotate other position to negative of this angle
    // to achieve straight line distance
    Offset rotated = rotatePoint(otherPosition - position, -angle);
    Offset distance = Offset(
      axis == Axis.horizontal ? rotated.dx : 0,
      axis == Axis.vertical ? rotated.dy : 0,
    );
    Offset rotatedBack = rotatePoint(distance, angle);
    return rotatedBack;
  }

  /// Snap to this snapping point
  /// returns the offset delta to snap to this point
  Offset? snapTo(SnappingPoint other, double threshold) {
    Offset? distance = distanceTo(other);
    if (distance == null) {
      return null;
    }
    double dist = distance.distance;
    if (dist < threshold) {
      return distance;
    }
    return null;
  }
}

class CanvasTransform {
  final Offset offset;
  final double zoom;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.zoom = 1,
  });

  Offset toLocal(Offset global) {
    return global / zoom - offset;
  }

  Offset toGlobal(Offset local) {
    return (local + offset) * zoom;
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

class CanvasItemNode {
  final CanvasItemNode? parent;
  final CanvasItem item;

  CanvasItemNode(this.parent, this.item);

  LayoutTransform? get parentTransform {
    if (parent == null) {
      return null;
    }
    CanvasItemNode? current = parent;
    LayoutTransform transform = LayoutTransform();
    while (current != null) {
      transform = current.item.transform * transform;
      current = current.parent;
    }
    return transform;
  }

  void visitTo(CanvasItem target, void Function(CanvasItem item) visitor) {
    CanvasItem current = item;
    while (current.isDescendantOf(target)) {
      visitor(current);
      bool found = false;
      for (final child in current.children) {
        if (child.isDescendantOf(target)) {
          current = child;
          found = true;
          break;
        }
      }
      if (!found) {
        break;
      }
    }
  }

  Offset toGlobal(Offset local) {
    CanvasItemNode? current = this;
    while (current != null) {
      local = current.item.transform.transformToParent(local);
      current = current.parent;
    }
    return local;
  }

  Offset toLocal(Offset global) {
    CanvasItemNode? current = this;
    while (current != null) {
      global = current.item.transform.transformFromParent(global);
      current = current.parent;
    }
    return global;
  }

  bool contains(Offset localPosition) {
    var scaledSize = item.transform.scaledSize;
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= scaledSize.width &&
        localPosition.dy <= scaledSize.height;
  }
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

  Polygon transformFromParentPolygon(Polygon polygon) {
    List<Offset> points = polygon.points.map(transformFromParent).toList();
    return Polygon(points);
  }

  Polygon transformToParentPolygon(Polygon polygon) {
    List<Offset> points = polygon.points.map(transformToParent).toList();
    return Polygon(points);
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
      scale: other.scale,
      size: other.size,
    );
  }

  @override
  String toString() {
    return 'LayoutTransform(offset: $offset, rotation: $rotation, scale: $scale, size: $size)';
  }
}

class LayoutSnapping {
  final SnappingConfiguration config;
  final List<SnappingPoint> snappingPoints = [];
  final CanvasItem? item;
  final LayoutTransform? parentTransform;
  late List<SnappingPoint> _selfSnappingPoints;

  Offset? newOffsetDelta;
  double? newRotationDelta;
  Offset? newScaleDelta;
  Offset? newSizeDelta;

  set newOffsetDeltaX(double value) {
    newOffsetDelta = Offset(value, newOffsetDelta?.dy ?? 0);
  }

  set newOffsetDeltaY(double value) {
    newOffsetDelta = Offset(newOffsetDelta?.dx ?? 0, value);
  }

  set newScaleDeltaX(double value) {
    newScaleDelta = Offset(value, newScaleDelta?.dy ?? 0);
  }

  set newScaleDeltaY(double value) {
    newScaleDelta = Offset(newScaleDelta?.dx ?? 0, value);
  }

  set newSizeDeltaX(double value) {
    newSizeDelta = Offset(value, newSizeDelta?.dy ?? 0);
  }

  set newSizeDeltaY(double value) {
    newSizeDelta = Offset(newSizeDelta?.dx ?? 0, value);
  }

  LayoutSnapping(this.config, CanvasItem this.item, this.parentTransform) {
    _selfSnappingPoints = _computeSnappingPoints(item!);
  }

  LayoutSnapping.noSnappingPoints(this.config)
      : item = null,
        parentTransform = null;

  List<SnappingPoint> get selfSnappingPoints => _selfSnappingPoints;

  List<SnappingPoint> _computeSnappingPoints(CanvasItem item) {
    List<SnappingPoint> snappingPoints = [];
    item.visitSnappingPoints((snappingPoint) {
      snappingPoints.add(snappingPoint);
    }, parentTransform);
    return snappingPoints;
  }
}

abstract class Layout {
  const Layout();
  void performLayout(CanvasItem item, [CanvasItem? parent]);
  void performSelfLayout(CanvasItem item);
  Layout drag(Offset delta, {LayoutSnapping? snapping});
  Layout rotate(double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping});
  Layout resizeTopLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping});
  Layout resizeTopRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping});
  Layout resizeBottomLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping});
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping});
  Layout resizeTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout resizeLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout resizeRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout resizeBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout rescaleTopLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping});
  Layout rescaleTopRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping});
  Layout rescaleBottomLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping});
  Layout rescaleBottomRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping});
  Layout rescaleTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout rescaleLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout rescaleRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  Layout rescaleBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping});
  bool get shouldHandleChildLayout;

  /// Transfer layout from parent to child
  Layout transferToParent(Layout parentLayout);

  /// Transfer layout from child to parent
  Layout transferToChild(Layout childLayout);
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

  @override
  String toString() {
    return 'AbsoluteLayout(offset: $offset, size: $size, rotation: ${radToDeg(rotation)}, scale: $scale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AbsoluteLayout &&
        other.offset == offset &&
        other.size == size &&
        other.rotation == rotation &&
        other.scale == scale;
  }

  @override
  int get hashCode {
    return Object.hash(offset, size, rotation, scale);
  }

  @override
  Layout transferToChild(Layout childLayout) {
    if (childLayout is AbsoluteLayout) {
      return AbsoluteLayout(
        offset: rotatePoint(offset - childLayout.offset, -childLayout.rotation),
        size: size,
        rotation: rotation - childLayout.rotation,
        scale: scale,
      );
    }
    return this;
  }

  @override
  Layout transferToParent(Layout parentLayout) {
    if (parentLayout is AbsoluteLayout) {
      return AbsoluteLayout(
        offset:
            rotatePoint(offset, parentLayout.rotation) + parentLayout.offset,
        size: size,
        rotation: rotation + parentLayout.rotation,
        scale: scale,
      );
    }
    return this;
  }

  Size get scaledSize => Size(size.width * scale.dx, size.height * scale.dy);

  double get aspectRatio {
    Size scaledSize = this.scaledSize;
    if (scaledSize.height == 0) {
      if (scaledSize.width == 0) {
        return 1;
      }
      return 0;
    }
    return scaledSize.width / scaledSize.height;
  }

  @override
  void performLayout(CanvasItem item, [CanvasItem? parent]) {
    if (parent != null && parent.layout.shouldHandleChildLayout) {
      parent.layoutListenable.value.performLayout(parent);
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
  Layout drag(Offset delta, {LayoutSnapping? snapping}) {
    var newOffset = offset + delta;
    if (snapping != null) {
      var oldNewOffset = newOffset;
      newOffset = snapping.config.snapToGrid(newOffset);
      snapping.newOffsetDelta = newOffset - oldNewOffset;
    }
    return AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  Layout rotate(double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping}) {
    double newRotation = rotation + delta;
    if (snapping != null) {
      var oldNewRotation = newRotation;
      newRotation = snapping.config.snapAngle(newRotation);
      snapping.newRotationDelta = delta - (oldNewRotation - newRotation);
    }
    Size scaledSize = this.scaledSize;
    Offset before = rotatePoint(-alignment.alongSize(scaledSize), rotation);
    Offset after = rotatePoint(-alignment.alongSize(scaledSize), newRotation);
    Offset offsetDelta = after - before;
    return AbsoluteLayout(
      offset: offset + offsetDelta,
      size: size,
      rotation: newRotation,
      scale: scale,
    );
  }

  @override
  Layout resizeBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width, size.height + delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        snapped.width - size.width,
        snapped.height - size.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      newSize = Size(size.width, size.height + snappedSizeDelta.dy / scale.dy);
    } else {
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height + delta.dy);
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeTop(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeBottomLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopRight(-delta, snapping: snapping);
    }
    return result;
  }

  @override
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopLeft(-delta, snapping: snapping);
    }
    return result;
  }

  @override
  Layout resizeLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();

    Offset newOffset;
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width - delta.dx, size.height);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        size.width - snapped.width,
        delta.dy,
      );
      snapping.newSizeDeltaX = snappedSizeDelta.dx;
      newSize = Size(size.width - snappedSizeDelta.dx / scale.dx, size.height);
      newOffset = offset + rotatePoint(snappedSizeDelta, rotation);
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation);
      delta = delta.divideBy(scale);
      newOffset = offset + rotatedDelta;
      newSize = Size(size.width - delta.dx, size.height);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeRight(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width + delta.dx, size.height);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        snapped.width - size.width,
        snapped.height - size.height,
      );
      snapping.newSizeDeltaX = snappedSizeDelta.dx;
      newSize = Size(size.width + snappedSizeDelta.dx / scale.dx, size.height);
    } else {
      delta = delta.divideBy(scale);
      newSize = Size(size.width + delta.dx, size.height);
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeLeft(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Size newSize;
    Offset newOffset;
    if (snapping != null) {
      newSize = Size(size.width, size.height - delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        0,
        size.height - snapped.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      newSize = Size(size.width, size.height - snappedSizeDelta.dy / scale.dy);
      newOffset = offset + rotatePoint(snappedSizeDelta, rotation);
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation);
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height - delta.dy);
      newOffset = offset + rotatedDelta;
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeBottom(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeTopLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeTop(delta, snapping: snapping)
        .resizeLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeBottomRight(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeTopRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    Layout result = resizeTop(delta, snapping: snapping)
        .resizeRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeBottomLeft(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    var newScale = Offset(scale.dx, scale.dy + delta.dy / size.height);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      newScale = Offset(scale.dx, snappedSize.height / size.height);
      snapping.newScaleDeltaY = snappedSize.height - oldScaledSize.height;
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleTop(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleBottomLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    Layout result = rescaleBottom(delta, snapping: snapping)
        .rescaleLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleTopRight(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleBottomRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    Layout result = rescaleBottom(delta, snapping: snapping)
        .rescaleRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleTopLeft(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    var newOffset = offset + rotatedDelta;
    var newScale = Offset(scale.dx - delta.dx / size.width, scale.dy);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      var snappedSizeDelta = Offset(
        snappedSize.width - oldScaledSize.width,
        snappedSize.height - oldScaledSize.height,
      );
      snappedSizeDelta = snapping.config.snapToGrid(snappedSizeDelta);
      var newScaleDelta = Offset(
        snappedSizeDelta.dx / size.width,
        snappedSizeDelta.dy / size.height,
      );
      snapping.newScaleDeltaX = -snappedSizeDelta.dx;
      newScale = scale + newScaleDelta;
      newOffset = offset - rotatePoint(snappedSizeDelta, rotation);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleRight(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    var newScale = Offset(scale.dx + delta.dx / size.width, scale.dy);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      newScale = Offset(snappedSize.width / size.width, scale.dy);
      snapping.newScaleDeltaX = snappedSize.width - oldScaledSize.width;
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleLeft(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    var newScale = Offset(scale.dx, scale.dy - delta.dy / size.height);
    var newOffset = offset + rotatedDelta;
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      var snappedSizeDelta = Offset(
        snappedSize.width - oldScaledSize.width,
        snappedSize.height - oldScaledSize.height,
      );
      snappedSizeDelta = snapping.config.snapToGrid(snappedSizeDelta);
      var newScaleDelta = Offset(
        snappedSizeDelta.dx / size.width,
        snappedSizeDelta.dy / size.height,
      );
      snapping.newScaleDeltaY = -snappedSizeDelta.dy;
      newScale = scale + newScaleDelta;
      newOffset = offset - rotatePoint(snappedSizeDelta, rotation);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result =
          result.rescaleBottom(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleTopLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleTop(delta, snapping: snapping)
        .rescaleLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleBottomRight(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleTopRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    Layout result = rescaleTop(delta, snapping: snapping)
        .rescaleRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleBottomLeft(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  bool get shouldHandleChildLayout => false;
}

abstract class CanvasItem implements CanvasParent {
  final ValueNotifier<Layout> _layoutNotifier =
      ValueNotifier(const AbsoluteLayout());
  final ValueNotifier<LayoutTransform> _transformNotifier =
      ValueNotifier(LayoutTransform());
  final ValueNotifier<List<CanvasItem>> _childrenNotifier = ValueNotifier([]);
  final ValueNotifier<bool> selectedNotifier = ValueNotifier(false);
  ValueListenable<Layout> get layoutListenable => _layoutNotifier;

  @override
  ValueListenable<List<CanvasItem>> get childListenable => _childrenNotifier;
  ValueListenable<LayoutTransform> get transformListenable =>
      _transformNotifier;

  Widget? build(BuildContext context) => null;

  Layout get layout => layoutListenable.value;

  String? get debugLabel => null;

  @override
  List<CanvasItem> get children => childListenable.value;
  LayoutTransform get transform => transformListenable.value;
  bool get selected => selectedNotifier.value;

  set transform(LayoutTransform transform) =>
      _transformNotifier.value = transform;

  final FocusNode decorationFocusNode = FocusNode();

  @override
  void addChildren(List<CanvasItem> children) {
    this.children = [...this.children, ...children];
  }

  @override
  void removeChildren(List<CanvasItem> children) {
    this.children =
        this.children.where((element) => !children.contains(element)).toList();
  }

  @override
  void addChild(CanvasItem child) {
    children = [...children, child];
  }

  @override
  void removeChild(CanvasItem child) {
    children = children.where((element) => element != child).toList();
  }

  @override
  void removeChildAt(int index) {
    children = List.from(children)..removeAt(index);
  }

  @override
  void insertChild(int index, CanvasItem child) {
    children = List.from(children)..insert(index, child);
  }

  bool get canTransform => true;

  set layout(Layout layout) {
    _layoutNotifier.value = layout;
    _handleLayoutChange();
  }

  void _handleLayoutChange() {
    layout.performLayout(this);
  }

  set children(List<CanvasItem> children) {
    _childrenNotifier.value = children;
    _handleLayoutChange();
  }

  set selected(bool selected) => selectedNotifier.value = selected;

  void visit(void Function(CanvasItem item) visitor) {
    visitor(this);
    for (final child in children) {
      child.visit(visitor);
    }
  }

  void visitTo(CanvasItem target, void Function(CanvasItem item) visitor) {
    CanvasItem current = this;
    while (current.isDescendantOf(target)) {
      visitor(current);
      bool found = false;
      for (final child in current.children) {
        if (child.isDescendantOf(target)) {
          current = child;
          found = true;
          break;
        }
      }
      if (!found) {
        break;
      }
    }
  }

  void hitTestSelection(CanvasHitTestResult result, Polygon selection,
      {SelectionBehavior behavior = SelectionBehavior.intersect,
      CanvasItemNode? parent}) {
    selection = transform.transformFromParentPolygon(selection);
    var node = toNode(parent);
    if (hitTestSelfSelection(selection, behavior)) {
      result.path.add(CanvasHitTestEntry(node, Offset.zero));
    }
    hitTestChildrenSelection(result, selection, node, behavior: behavior);
  }

  void hitTestChildrenSelection(
      CanvasHitTestResult result, Polygon selection, CanvasItemNode node,
      {SelectionBehavior behavior = SelectionBehavior.intersect}) {
    for (final child in children) {
      child.hitTestSelection(result, selection,
          behavior: behavior, parent: node);
    }
  }

  void hitTest(CanvasHitTestResult result, Offset position,
      [CanvasItemNode? parent]) {
    position = transform.transformFromParent(position);
    var node = toNode(parent);
    if (hitTestSelf(position)) {
      result.path.add(CanvasHitTestEntry(node, position));
    }
    hitTestChildren(result, position, node);
  }

  void hitTestChildren(
      CanvasHitTestResult result, Offset position, CanvasItemNode node) {
    for (final child in children) {
      child.hitTest(result, position, node);
    }
  }

  bool isDescendantOf(CanvasItem item) {
    if (item == this) {
      return true;
    }
    for (final child in children) {
      if (child.isDescendantOf(item)) {
        return true;
      }
    }
    return false;
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
    visitor(SnappingPoint(
        position: topLeft,
        angle: currentTransform.rotation,
        axis: Axis.horizontal));
    visitor(SnappingPoint(
        position: topRight,
        angle: currentTransform.rotation,
        axis: Axis.horizontal));
    visitor(SnappingPoint(
        position: bottomLeft,
        angle: currentTransform.rotation,
        axis: Axis.horizontal));
    visitor(SnappingPoint(
        position: bottomRight,
        angle: currentTransform.rotation,
        axis: Axis.horizontal));
    visitor(SnappingPoint(
        position: center,
        angle: currentTransform.rotation,
        axis: Axis.horizontal));
    // rotated y-axis snapping points
    visitor(SnappingPoint(
        position: topLeft,
        angle: currentTransform.rotation,
        axis: Axis.vertical));
    visitor(SnappingPoint(
        position: topRight,
        angle: currentTransform.rotation,
        axis: Axis.vertical));
    visitor(SnappingPoint(
        position: bottomLeft,
        angle: currentTransform.rotation,
        axis: Axis.vertical));
    visitor(SnappingPoint(
        position: bottomRight,
        angle: currentTransform.rotation,
        axis: Axis.vertical));
    visitor(SnappingPoint(
        position: center,
        angle: currentTransform.rotation,
        axis: Axis.vertical));
    // unrotated x-axis snapping points
    visitor(SnappingPoint(position: topLeft, angle: 0, axis: Axis.horizontal));
    visitor(SnappingPoint(position: topRight, angle: 0, axis: Axis.horizontal));
    visitor(
        SnappingPoint(position: bottomLeft, angle: 0, axis: Axis.horizontal));
    visitor(
        SnappingPoint(position: bottomRight, angle: 0, axis: Axis.horizontal));
    visitor(SnappingPoint(position: center, angle: 0, axis: Axis.horizontal));
    // unrotated y-axis snapping points
    visitor(SnappingPoint(
        position: topLeft, angle: degToRad(90), axis: Axis.vertical));
    visitor(SnappingPoint(
        position: topRight, angle: degToRad(90), axis: Axis.vertical));
    visitor(SnappingPoint(
        position: bottomLeft, angle: degToRad(90), axis: Axis.vertical));
    visitor(SnappingPoint(
        position: bottomRight, angle: degToRad(90), axis: Axis.vertical));
    visitor(SnappingPoint(position: center, angle: 0, axis: Axis.vertical));
    for (final child in children) {
      child.visitSnappingPoints(visitor, currentTransform);
    }
  }

  bool hitTestSelf(Offset position) {
    var scaledSize = transform.scaledSize;
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx <= scaledSize.width &&
        position.dy <= scaledSize.height;
  }

  bool hitTestSelfSelection(Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.intersect]) {
    var scaledSize = transform.scaledSize;
    Polygon box = Polygon.fromRect(
        Rect.fromLTWH(0, 0, scaledSize.width, scaledSize.height));
    switch (behavior) {
      case SelectionBehavior.intersect:
        return box.overlaps(selection);
      case SelectionBehavior.contain:
        return selection.containsPolygon(box);
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
  bool get canTransform => false;

  @override
  bool hitTestSelf(Offset position) {
    return false;
  }

  @override
  bool hitTestSelfSelection(Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.intersect]) {
    return false;
  }
}

class CanvasItemAdapter extends CanvasItem {
  @override
  final String? debugLabel;
  CanvasItemAdapter({
    this.debugLabel,
    List<CanvasItem> children = const [],
    Layout layout = const AbsoluteLayout(),
    bool selected = false,
  }) {
    this.children = children;
    this.layout = layout;
    this.selected = selected;
  }

  @override
  String toString() {
    return '$runtimeType($debugLabel)';
  }
}

class BoxCanvasItem extends CanvasItemAdapter {
  final Widget? decoration;
  BoxCanvasItem({
    this.decoration,
    super.children = const [],
    required super.layout,
    super.debugLabel,
    super.selected = false,
  });

  @override
  Widget? build(BuildContext context) {
    return decoration;
  }
}

abstract class TransformControl {
  const TransformControl();
  Widget build(BuildContext context, CanvasItemNode node);
}
