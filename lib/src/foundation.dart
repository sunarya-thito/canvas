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
  ValueListenable<List<CanvasItem>> get childrenListenable;
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

mixin CanvasElementDragger {
  void handleDragAdjustment(Offset delta);
}

mixin CanvasViewportHandle {
  CanvasTransform get transform;
  Size get size;
  set transform(CanvasTransform transform);
  ValueListenable<CanvasTransform> get transformListenable;
  void drag(Offset delta);
  void zoomAt(Offset position, double delta);
  Offset get canvasOffset;
  CanvasViewportThemeData get theme;
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
  LayoutSnapping createLayoutSnapping(CanvasItem node,
      [bool fillInSnappingPoints = true]);
  ValueListenable<CanvasItem?> get reparentTargetListenable;

  CanvasItem? get hoveredItem;
  ValueListenable<CanvasItem?> get hoveredItemListenable;

  CanvasItem? get focusedItem;
  ValueListenable<CanvasItem?> get focusedItemListenable;
  void markFocused(CanvasItem node);
  void startDraggingSession(CanvasElementDragger owner);
  void endDraggingSession(CanvasElementDragger owner);
  CanvasHitTestResult hitTestAtCursor();

  void handleReparenting(CanvasItem? target);
  bool canReparent(CanvasItem item, CanvasItem target);

  void fillInSnappingPoints(LayoutSnapping layoutSnapping) {
    visitSnappingPoints(
      (snappingPoint) {
        layoutSnapping.snappingPoints.add(snappingPoint);
      },
    );
  }

  void visit(void Function(CanvasItem item) visitor) {
    controller.root.visit(visitor);
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    controller.root.hitTest(result, position);
  }

  void visitWithTransform(
      void Function(CanvasItem item, LayoutTransform? parentTransform) visitor,
      {bool rootSelectionOnly = false}) {
    controller.root
        .visitWithTransform(visitor, rootSelectionOnly: rootSelectionOnly);
  }

  void visitSnappingPoints(void Function(SnappingPoint snappingPoint) visitor) {
    controller.root.visitSnappingPoints(visitor);
  }

  TransformSession beginTransform(
      {bool rootSelectionOnly = false, bool selectedOnly = true}) {
    final nodes = <TransformNode>[];
    visitWithTransform((item, parentTransform) {
      if (item.selected || !selectedOnly) {
        nodes.add(
            TransformNode(item, item.transform, parentTransform, item.layout));
      }
    }, rootSelectionOnly: rootSelectionOnly);
    return TransformSession(nodes);
  }
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
    if (gridSnapping == null || gridSnapping == Offset.zero) {
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

  @override
  String toString() {
    return 'CanvasTransform(offset: $offset, zoom: $zoom)';
  }
}

typedef Snapper = Offset? Function(SnappingPoint snappingPoint);

class ReparentDetails {
  final CanvasItem item;
  final CanvasItem oldParent;
  final CanvasItem newParent;

  ReparentDetails({
    required this.item,
    required this.oldParent,
    required this.newParent,
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

abstract class LayoutChanges {
  double get aspectRatio;
  double get rotation;
  Size get scaledSize;
  Size get size;
  Offset get offset;
  Offset get scale;
  void reset();
  void drag(Offset delta);
  void rotate(double delta, {Alignment alignment = Alignment.center}) {
    double newRotation = rotation + delta;
    Size scaledSize = this.scaledSize;
    Offset before = rotatePoint(-alignment.alongSize(scaledSize), rotation);
    Offset after = rotatePoint(-alignment.alongSize(scaledSize), newRotation);
    Offset offsetDelta = after - before;
    drag(offsetDelta);
    handleRotate(delta);
  }

  void resizeTopLeft(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    handleResizeTopLeft(delta);
    if (symmetric) {
      handleResizeBottomRight(-delta);
    }
  }

  void resizeTopRight(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    handleResizeTopRight(delta);
    if (symmetric) {
      handleResizeBottomLeft(-delta);
    }
  }

  void resizeBottomLeft(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    handleResizeBottomLeft(delta);
    if (symmetric) {
      handleResizeTopRight(-delta);
    }
  }

  void resizeBottomRight(Offset delta,
      {bool proportional = false, bool symmetric = false}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    handleResizeBottomRight(delta);
    if (symmetric) {
      handleResizeTopLeft(-delta);
    }
  }

  void resizeTop(Offset delta, {bool symmetric = false}) {
    handleResizeTop(delta);
    if (symmetric) {
      handleResizeBottom(-delta);
    }
  }

  void resizeLeft(Offset delta, {bool symmetric = false}) {
    handleResizeLeft(delta);
    if (symmetric) {
      handleResizeRight(-delta);
    }
  }

  void resizeRight(Offset delta, {bool symmetric = false}) {
    handleResizeRight(delta);
    if (symmetric) {
      handleResizeLeft(-delta);
    }
  }

  void resizeBottom(Offset delta, {bool symmetric = false}) {
    handleResizeBottom(delta);
    if (symmetric) {
      handleResizeTop(-delta);
    }
  }

  void rescaleTopLeft(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    handleRescaleTopLeft(delta);
    if (symmetric) {
      handleRescaleBottomRight(-delta);
    }
  }

  void rescaleTopRight(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    handleRescaleTopRight(delta);
    if (symmetric) {
      handleRescaleBottomLeft(-delta);
    }
  }

  void rescaleBottomLeft(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    handleRescaleBottomLeft(delta);
    if (symmetric) {
      handleRescaleTopRight(-delta);
    }
  }

  void rescaleBottomRight(Offset delta,
      {bool symmetric = false, bool proportional = false}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    handleRescaleBottomRight(delta);
    if (symmetric) {
      handleRescaleTopLeft(-delta);
    }
  }

  void rescaleTop(Offset delta, {bool symmetric = false}) {
    handleRescaleTop(delta);
    if (symmetric) {
      handleRescaleBottom(-delta);
    }
  }

  void rescaleLeft(Offset delta, {bool symmetric = false}) {
    handleRescaleLeft(delta);
    if (symmetric) {
      handleRescaleRight(-delta);
    }
  }

  void rescaleRight(Offset delta, {bool symmetric = false}) {
    handleRescaleRight(delta);
    if (symmetric) {
      handleRescaleLeft(-delta);
    }
  }

  void rescaleBottom(Offset delta, {bool symmetric = false}) {
    handleRescaleBottom(delta);
    if (symmetric) {
      handleRescaleTop(-delta);
    }
  }

  void handleRotate(double delta);

  void handleRescaleTopLeft(Offset delta) {
    handleRescaleTop(delta);
    handleRescaleLeft(delta);
  }

  void handleRescaleTopRight(Offset delta) {
    handleRescaleTop(delta);
    handleRescaleRight(delta);
  }

  void handleRescaleBottomLeft(Offset delta) {
    handleRescaleBottom(delta);
    handleRescaleLeft(delta);
  }

  void handleRescaleBottomRight(Offset delta) {
    handleRescaleBottom(delta);
    handleRescaleRight(delta);
  }

  void handleResizeTopLeft(Offset delta) {
    handleResizeTop(delta);
    handleResizeLeft(delta);
  }

  void handleResizeTopRight(Offset delta) {
    handleResizeTop(delta);
    handleResizeRight(delta);
  }

  void handleResizeBottomLeft(Offset delta) {
    handleResizeBottom(delta);
    handleResizeLeft(delta);
  }

  void handleResizeBottomRight(Offset delta) {
    handleResizeBottom(delta);
    handleResizeRight(delta);
  }

  void handleRescaleTop(Offset delta);
  void handleRescaleLeft(Offset delta);
  void handleRescaleRight(Offset delta);
  void handleRescaleBottom(Offset delta);

  void handleResizeTop(Offset delta);
  void handleResizeLeft(Offset delta);
  void handleResizeRight(Offset delta);
  void handleResizeBottom(Offset delta);

  void snap(LayoutSnapping snapping);

  Layout apply(Layout layout);
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

abstract class CanvasItem implements CanvasParent {
  final ValueNotifier<CanvasItem?> _parentNotifier = ValueNotifier(null);
  final ValueNotifier<Layout> _layoutNotifier =
      ValueNotifier(const AbsoluteLayout());
  final ValueNotifier<LayoutTransform> _transformNotifier =
      ValueNotifier(LayoutTransform());
  final ValueNotifier<List<CanvasItem>> _childrenNotifier = ValueNotifier([]);
  final ValueNotifier<bool> selectedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> clipContentNotifier = ValueNotifier(true);
  ValueListenable<Layout> get layoutListenable => _layoutNotifier;

  CanvasItem() {
    layoutListenable.addListener(_handleLayoutChange);
  }

  bool get clipContent => clipContentNotifier.value;
  set clipContent(bool clipContent) => clipContentNotifier.value = clipContent;

  @override
  ValueListenable<List<CanvasItem>> get childrenListenable => _childrenNotifier;
  ValueListenable<LayoutTransform> get transformListenable =>
      _transformNotifier;

  Widget? build(BuildContext context) => null;

  Layout get layout => layoutListenable.value;

  String? get debugLabel => null;

  @override
  List<CanvasItem> get children => childrenListenable.value;
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
    List<CanvasItem> newChildren = List.from(children);
    children = newChildren;
  }

  @override
  void insertChild(int index, CanvasItem child) {
    children = List.from(children)..insert(index, child);
  }

  CanvasItem? get parent => _parentNotifier.value;
  ValueListenable<CanvasItem?> get parentListenable => _parentNotifier;

  LayoutTransform? get parentTransform {
    var parent = _parentNotifier.value;
    if (parent == null) {
      return null;
    }
    LayoutTransform transform = LayoutTransform();
    while (parent != null) {
      transform = transform * parent.transform;
      parent = parent._parentNotifier.value;
    }
    return transform;
  }

  LayoutTransform get globalTransform {
    var transform = this.transform;
    var parentTransform = this.parentTransform;
    if (parentTransform != null) {
      transform = parentTransform * transform;
    }
    return transform;
  }

  bool get opaque => true;

  set layout(Layout layout) {
    _layoutNotifier.value = layout;
  }

  void _handleLayoutChange() {
    layout.performLayout(this);
  }

  set children(List<CanvasItem> children) {
    var oldChildren = this.children;
    for (final child in children) {
      if (!oldChildren.contains(child)) {
        assert(child._parentNotifier.value == null,
            'Child $child already has a parent ${child._parentNotifier.value}');
        child._parentNotifier.value = this;
      }
    }
    for (final child in oldChildren) {
      if (!children.contains(child)) {
        child._parentNotifier.value = null;
      }
    }
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
      {SelectionBehavior behavior = SelectionBehavior.intersect}) {
    selection = transform.transformFromParentPolygon(selection);
    hitTestChildrenSelection(result, selection, behavior: behavior);
    if (hitTestSelfSelection(selection, behavior)) {
      result.path.add(CanvasHitTestEntry(this, Offset.zero));
    }
  }

  void hitTestChildrenSelection(CanvasHitTestResult result, Polygon selection,
      {SelectionBehavior behavior = SelectionBehavior.intersect}) {
    for (int i = children.length - 1; i >= 0; i--) {
      children[i].hitTestSelection(result, selection, behavior: behavior);
    }
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    position = transform.transformFromParent(position);
    hitTestChildren(result, position);
    if (hitTestSelf(position)) {
      result.path.add(CanvasHitTestEntry(this, position));
    }
  }

  void storeHitTest(CanvasHitTestResult result,
      [Offset position = Offset.zero]) {
    result.path.add(CanvasHitTestEntry(this, position));
  }

  void hitTestChildren(CanvasHitTestResult result, Offset position) {
    for (int i = children.length - 1; i >= 0; i--) {
      children[i].hitTest(result, position);
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
    if (opaque) {
      visitor(this, parentTransform);
    }
    if (rootSelectionOnly && selected && opaque) {
      return;
    }
    for (final child in children) {
      child.visitWithTransform(visitor,
          parentTransform: transform, rootSelectionOnly: rootSelectionOnly);
    }
  }

  void visitSnappingPoints(void Function(SnappingPoint snappingPoint) visitor,
      [LayoutTransform? parentTransform]) {
    var currentTransform =
        parentTransform == null ? transform : parentTransform * transform;
    if (opaque) {
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
      visitor(
          SnappingPoint(position: topLeft, angle: 0, axis: Axis.horizontal));
      visitor(
          SnappingPoint(position: topRight, angle: 0, axis: Axis.horizontal));
      visitor(
          SnappingPoint(position: bottomLeft, angle: 0, axis: Axis.horizontal));
      visitor(SnappingPoint(
          position: bottomRight, angle: 0, axis: Axis.horizontal));
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
    }
    for (final child in children) {
      child.visitSnappingPoints(visitor, currentTransform);
    }
  }

  void remove() {
    var parent = _parentNotifier.value;
    if (parent != null) {
      parent.removeChild(this);
    }
  }

  bool get hasContent => children.isNotEmpty;

  bool hitTestSelf(Offset position) {
    if (!opaque) {
      return false;
    }
    var box = boundingBox;
    return box.contains(position);
  }

  Polygon get boundingBox {
    var size = transform.scaledSize;
    return Polygon.fromRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  Polygon get globalBoundingBox {
    return globalTransform.transformToParentPolygon(boundingBox);
  }

  bool hitTestSelfSelection(Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.intersect]) {
    if (!opaque) {
      return false;
    }
    var box = boundingBox;
    switch (behavior) {
      case SelectionBehavior.intersect:
        return box.overlaps(selection);
      case SelectionBehavior.contain:
        return selection.containsPolygon(box);
    }
  }

  Offset toGlobal(Offset position) {
    return globalTransform.transformToParent(position);
  }

  Offset toLocal(Offset position) {
    return globalTransform.transformFromParent(position);
  }
}

class _FinalValueNotifier<T> extends ValueNotifier<T> {
  _FinalValueNotifier(T value) : super(value);

  @override
  set value(T newValue) {
    // ignore
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

  final ValueNotifier<bool> _selectedNotifier = _FinalValueNotifier(true);

  final ValueNotifier<bool> _clipContentNotifier = _FinalValueNotifier(false);

  final ValueNotifier<bool> _contentFocusedNotifier = _FinalValueNotifier(true);

  @override
  ValueNotifier<bool> get selectedNotifier => _selectedNotifier;

  @override
  ValueNotifier<bool> get clipContentNotifier => _clipContentNotifier;

  @override
  bool get opaque => false;

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
  Widget build(BuildContext context, CanvasItem item, bool canTransform);
}
