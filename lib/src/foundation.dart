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
  overlap,
  contain,
}

abstract class CanvasSelectionHandler {
  CanvasSelectionSession onSelectionStart(CanvasSelectSession session);
  void onInstantSelection(Offset position);
  bool get shouldCancelObjectDragging;
}

abstract class CanvasSelectionSession {
  void onSelectionChange(CanvasSelectSession session, Offset delta);
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

  const SnappingConfiguration({
    this.enableObjectSnapping = true,
    this.enableRotationSnapping = true,
    this.threshold = 5,
    this.angles = defaultSnappingAngles,
  });

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

  SnappingPoint({
    required this.position,
    required this.angle,
  });
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
  final CanvasItem item;
  final LayoutTransform? parentTransform;
  late List<SnappingPoint> _selfSnappingPoints;

  Offset? newOffsetDelta;
  double? newRotationDelta;
  Offset? newScaleDelta;
  Offset? newSizeDelta;

  LayoutSnapping(this.config, this.item, this.parentTransform) {
    _selfSnappingPoints = _computeSnappingPoints(item);
  }

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
        // offset: offset - childLayout.offset,
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
        // offset: offset + parentLayout.offset,
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
    return AbsoluteLayout(
      offset: offset + delta,
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
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopRight(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopLeft(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
  Layout resizeRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
  Layout resizeTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
      delta = proportionalDelta(delta, aspectRatio);
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
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
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
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
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
  Layout rescaleLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
  Layout rescaleRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
  Layout rescaleTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
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
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
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
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
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
      [SelectionBehavior behavior = SelectionBehavior.overlap]) {
    selection = transform.transformFromParentPolygon(selection);
    if (hitTestSelfSelection(selection, behavior)) {
      result.path.add(CanvasHitTestEntry(this, Offset.zero));
    }
    hitTestChildrenSelection(result, selection, behavior);
  }

  bool hitTestSelfSelection(Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.overlap]) {
    return false;
  }

  void hitTestChildrenSelection(CanvasHitTestResult result, Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.overlap]) {
    for (final child in children) {
      child.hitTestSelection(result, selection, behavior);
    }
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    position = transform.transformFromParent(position);
    if (hitTestSelf(position)) {
      result.path.add(CanvasHitTestEntry(this, position));
    }
    hitTestChildren(result, position);
  }

  bool hitTestSelf(Offset position) {
    return false;
  }

  void hitTestChildren(CanvasHitTestResult result, Offset position) {
    for (final child in children) {
      child.hitTest(result, position);
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
}

class BoxCanvasItem extends CanvasItem {
  final Widget? decoration;
  @override
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
  Widget? build(BuildContext context) {
    return decoration;
  }

  @override
  bool hitTestSelf(Offset position) {
    var scaledSize = transform.scaledSize;
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx <= scaledSize.width &&
        position.dy <= scaledSize.height;
  }

  @override
  bool hitTestSelfSelection(Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.overlap]) {
    var scaledSize = transform.scaledSize;
    Polygon box = Polygon.fromRect(
        Rect.fromLTWH(0, 0, scaledSize.width, scaledSize.height));
    switch (behavior) {
      case SelectionBehavior.overlap:
        return box.overlaps(selection);
      case SelectionBehavior.contain:
        return selection.containsPolygon(box);
    }
  }

  @override
  String toString() {
    return 'BoxCanvasItem($debugLabel)';
  }
}

abstract class TransformControl {
  const TransformControl();
  Widget build(BuildContext context, CanvasItemNode node);
}
