import 'dart:collection';

import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../canvas.dart';

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
  LayoutSnapping createLayoutSnapping(Predicate<CanvasItem> predicate);
  ValueListenable<CanvasItem?> get reparentTargetListenable;

  void visitSnappingPoints(
      void Function(CanvasItem item, SnappingPoint snappingPoint) visitor,
      SnappingToggle snappingToggle,
      [bool snapToCanvas = true]);

  CanvasItem? get hoveredItem;
  ValueListenable<CanvasItem?> get hoveredItemListenable;

  CanvasItem? get focusedItem;
  ValueListenable<CanvasItem?> get focusedItemListenable;
  void markFocused(CanvasItem node);
  void markSnappingTarget(
      CanvasElementDragger owner, SnappingResult? snappingPoint);
  void startDraggingSession(CanvasElementDragger owner);
  void endDraggingSession(CanvasElementDragger owner);
  CanvasHitTestResult hitTestAtCursor();

  void handleReparenting(CanvasItem? target);
  bool canReparent(CanvasItem item, CanvasItem target);

  void visit(void Function(CanvasItem item) visitor) {
    controller.root.visit(visitor);
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    controller.root.hitTest(result, position);
  }

  void visitWithTransform(
      void Function(CanvasItem item, Matrix4? parentTransform) visitor,
      {bool rootSelectionOnly = false}) {
    controller.root
        .visitWithTransform(visitor, rootSelectionOnly: rootSelectionOnly);
  }

  TransformSession beginTransform(
      {bool rootSelectionOnly = false, bool selectedOnly = true}) {
    final nodes = <TransformNode>[];
    visitWithTransform((item, parentTransform) {
      if (item.selected || !selectedOnly) {
        nodes.add(TransformNode(
            item, item.transform, parentTransform, item.constraints));
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

class SnappingToggle {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final bool center;
  final bool top;
  final bool left;
  final bool right;
  final bool bottom;
  final bool normal;
  final bool rotated;

  const SnappingToggle({
    this.topLeft = true,
    this.topRight = true,
    this.bottomLeft = true,
    this.bottomRight = true,
    this.center = false,
    this.top = false,
    this.left = false,
    this.right = false,
    this.bottom = false,
    this.normal = false,
    this.rotated = true,
  });

  SnappingToggle copyWith({
    bool? topLeft,
    bool? topRight,
    bool? bottomLeft,
    bool? bottomRight,
    bool? center,
    bool? top,
    bool? left,
    bool? right,
    bool? bottom,
    bool? normal,
    bool? rotated,
  }) {
    return SnappingToggle(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      center: center ?? this.center,
      top: top ?? this.top,
      left: left ?? this.left,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      normal: normal ?? this.normal,
      rotated: rotated ?? this.rotated,
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
  final double rotationSnappingThreshold;
  final double objectSnappingThreshold;
  final List<double> angles;
  final Offset? gridSnapping;
  final SnappingToggle snappingToggle;
  final bool snapToCanvas;

  const SnappingConfiguration({
    this.enableObjectSnapping = true,
    this.enableRotationSnapping = true,
    this.rotationSnappingThreshold = 5,
    this.objectSnappingThreshold = 10,
    this.angles = defaultSnappingAngles,
    this.snappingToggle = const SnappingToggle(),
    this.gridSnapping,
    this.snapToCanvas = true,
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
      if (diff < rotationSnappingThreshold) {
        return degToRad(snappingAngle);
      }
    }
    return degToRad(angle);
  }
}

class Snap {
  final SnappingPoint target;
  final Axis direction;
  final double rotation;
  final Offset delta;

  Snap({
    required this.target,
    required this.direction,
    required this.rotation,
    required this.delta,
  });

  Offset get position => target.position;
}

class SnappingPoint {
  final Offset position;
  final double angle;

  SnappingPoint({
    required this.position,
    required this.angle,
  });

  SnappingPoint copyWith({
    Offset? position,
    double? angle,
  }) {
    return SnappingPoint(
      position: position ?? this.position,
      angle: angle ?? this.angle,
    );
  }

  Snap? _distanceTo(SnappingPoint target, Axis targetDirection, bool rotated) {
    Offset otherPosition = target.position;
    double totalRotation = 0;
    if (rotated) {
      totalRotation += angle;
    }
    if (targetDirection == Axis.horizontal) {
      totalRotation += kDeg90;
    }
    Offset rotatedPosition =
        rotatePoint(otherPosition - position, totalRotation);
    Offset distance = Offset(
      targetDirection == Axis.horizontal ? rotatedPosition.dx : 0,
      targetDirection == Axis.vertical ? rotatedPosition.dy : 0,
    );
    Offset rotatedBack = rotatePoint(distance, -totalRotation);
    return Snap(
      target: target.copyWith(
        angle: totalRotation,
      ),
      direction: targetDirection,
      rotation: totalRotation,
      delta: rotatedBack,
    );
    // // rotate other position to negative of this angle
    // // to achieve straight line distance
    // Offset rotated = rotatePoint(otherPosition - position, -otherAngle);
    // Offset distance = Offset(
    //   direction == Axis.horizontal ? rotated.dx : 0,
    //   direction == Axis.vertical ? rotated.dy : 0,
    // );
    // Offset rotatedBack = rotatePoint(distance, otherAngle);
    // return Snap(
    //     target: other.copyWith(
    //       angle: otherAngle,
    //     ),
    //     delta: rotatedBack);
  }

  /// Snap to this snapping point
  /// returns the offset delta to snap to this point
  Snap? snapTo(
      SnappingPoint target, double threshold, Axis direction, bool rotated) {
    Snap? distance = _distanceTo(target, direction, rotated);
    if (distance == null) {
      return null;
    }
    double dist = distance.delta.distance;
    if (dist < threshold) {
      return distance;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SnappingPoint &&
        other.position == position &&
        other.angle == angle;
  }

  @override
  String toString() {
    return 'SnappingPoint(position: $position, angle: $angle)';
  }

  @override
  int get hashCode {
    return Object.hash(position, angle);
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
  final Offset shear;
  final Size size;

  const LayoutTransform({
    this.offset = Offset.zero,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
    this.size = Size.zero,
    this.shear = Offset.zero,
  });

  void _debugValidate() {
    assert(size.width.isFinite, 'Width is not finite ($this)');
    assert(size.height.isFinite, 'Height is not finite ($this)');
    assert(scale.dx.isFinite, 'Scale dx is not finite ($this)');
    assert(scale.dy.isFinite, 'Scale dy is not finite ($this)');
    assert(offset.dx.isFinite, 'Offset dx is not finite ($this)');
    assert(offset.dy.isFinite, 'Offset dy is not finite ($this)');
    assert(rotation.isFinite, 'Rotation is not finite ($this)');
    assert(shear.dx.isFinite, 'Shear dx is not finite ($this)');
    assert(shear.dy.isFinite, 'Shear dy is not finite ($this)');
  }

  // TODO: this
  // List<SnappingPoint> getSnappingPoints(SnappingLocation location) {}

  // TODO: remove this, we added shear, so it's not a simple scale anymore
  Size get scaledSize => Size(size.width * scale.dx, size.height * scale.dy);

  // Offset transformFromParent(Offset offset) {
  //   offset = offset - this.offset;
  //   offset = offset.scale(1 / scale.dx, 1 / scale.dy);
  //   offset = rotatePoint(offset, -rotation);
  //   return offset;
  // }

  // Offset transformToParent(Offset offset) {
  //   offset = rotatePoint(offset, rotation);
  //   offset = offset.scale(scale.dx, scale.dy);
  //   offset = offset + this.offset;
  //   return offset;
  // }
  //
  // Polygon transformFromParentPolygon(Polygon polygon) {
  //   List<Offset> points = polygon.points.map(transformFromParent).toList();
  //   return Polygon(points);
  // }
  //
  // Polygon transformToParentPolygon(Polygon polygon) {
  //   List<Offset> points = polygon.points.map(transformToParent).toList();
  //   return Polygon(points);
  // }

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

  Matrix4 toMatrix4() {
    Matrix4 matrix = Matrix4.identity();
    matrix.translate(offset.dx, offset.dy);
    matrix.shearMatrix(shear);
    matrix.rotateZ(rotation);
    matrix.scale(scale.dx, scale.dy);
    return matrix;
  }

  Matrix4 toNonTranslatedMatrix4() {
    Matrix4 matrix = Matrix4.identity();
    matrix.shearMatrix(shear);
    matrix.rotateZ(rotation);
    matrix.scale(scale.dx, scale.dy);
    return matrix;
  }

  Offset transformPanDelta(Offset delta) {
    return Offset(delta.dx / scale.dx, delta.dy / scale.dy);
  }

  Matrix4 toInverseMatrix4() {
    return Matrix4.inverted(toMatrix4());
  }

  @override
  String toString() {
    return 'LayoutTransform(offset: $offset, rotation: $rotation, scale: $scale, size: $size)';
  }
}

class SnappingResult {
  final Snap mainAxisTarget;
  final Snap? crossAxisTarget;
  final Offset delta;

  const SnappingResult({
    required this.mainAxisTarget,
    this.crossAxisTarget,
    required this.delta,
  });
}

enum SnappingLocation {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
  top,
  left,
  right,
  bottom,
}

class LayoutSnapping {
  final SnappingConfiguration config;
  final List<SnappingPoint> snappingPoints = [];

  Offset? newOffsetDelta;
  double? newRotationDelta;
  Offset? newScaleDelta;
  Offset? newSizeDelta;
  SnappingResult? snappedPoint;

  SnappingResult? findSnappingTarget(List<SnappingPoint> points) {
    for (final snappingPoint in points) {
      SnappingResult? result = testSnappingTarget(snappingPoint, false);
      if (result != null) {
        return result;
      }
      SnappingResult? rotatedResult = testSnappingTarget(snappingPoint, true);
      if (rotatedResult != null) {
        return rotatedResult;
      }
    }
    return null;
  }

  SnappingResult? testSnappingTarget(SnappingPoint point, bool rotated) {
    double? minDistanceHorizontal;
    double? minDistanceVertical;
    Snap? targetHorizontal;
    Snap? targetVertical;
    for (final snappingPoint in snappingPoints) {
      Snap? resultHorizontal = point.snapTo(snappingPoint,
          config.objectSnappingThreshold, Axis.horizontal, rotated);
      Snap? resultVertical = point.snapTo(snappingPoint,
          config.objectSnappingThreshold, Axis.vertical, rotated);
      if (resultHorizontal != null) {
        double distance = resultHorizontal.delta.distance;
        if (minDistanceHorizontal == null || distance < minDistanceHorizontal) {
          minDistanceHorizontal = distance;
          targetHorizontal = resultHorizontal;
        }
      }
      if (resultVertical != null) {
        double distance = resultVertical.delta.distance;
        if (minDistanceVertical == null || distance < minDistanceVertical) {
          minDistanceVertical = distance;
          targetVertical = resultVertical;
        }
      }
    }
    if (targetHorizontal != null || targetVertical != null) {
      return SnappingResult(
        mainAxisTarget: targetHorizontal ?? targetVertical!,
        crossAxisTarget: targetHorizontal != null ? targetVertical : null,
        delta: Offset.zero,
      );
    }
    return null;
  }

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

  LayoutSnapping(this.config);
}

abstract class Layout {
  const Layout();
  bool needsRelayout(CanvasItem item) {
    if (item._isDirty) {
      return true;
    }
    for (final child in item.children) {
      if (needsRelayout(child)) {
        return true;
      }
    }
    return false;
  }

  double computeIntrinsicHeight(CanvasItem item);
  double computeIntrinsicWidth(CanvasItem item);

  void performLayout(CanvasItem item, BoxConstraints constraints);
}

abstract class ItemConstraints {
  const ItemConstraints();
  double get rotation;
  bool get constrainedByParent => false;
  LayoutTransform constrain(CanvasItem item, BoxConstraints constraints);
  ItemConstraints drag(CanvasItem item, Offset delta,
      {LayoutSnapping? snapping});
  ItemConstraints rotate(CanvasItem item, double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping});
  ItemConstraints resizeTopLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft});
  ItemConstraints resizeTopRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight});
  ItemConstraints resizeBottomLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft});
  ItemConstraints resizeBottomRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight});
  ItemConstraints resizeTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top});
  ItemConstraints resizeLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left});
  ItemConstraints resizeRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right});
  ItemConstraints resizeBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom});
  ItemConstraints rescaleTopLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft});
  ItemConstraints rescaleTopRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight});
  ItemConstraints rescaleBottomLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft});
  ItemConstraints rescaleBottomRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight});
  ItemConstraints rescaleTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top});
  ItemConstraints rescaleLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left});
  ItemConstraints rescaleRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right});
  ItemConstraints rescaleBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom});

  /// Transfer layout from parent to child
  ItemConstraints transferToParent(ItemConstraints parentLayout);

  /// Transfer layout from child to parent
  ItemConstraints transferToChild(ItemConstraints childLayout);
}

base class CanvasItemEntry extends LinkedListEntry<CanvasItemEntry> {
  final CanvasItem item;

  CanvasItemEntry(this.item);
}

class CanvasItem {
  final String? debugLabel;
  final ValueNotifier<CanvasItem?> _parentNotifier = ValueNotifier(null);
  final ValueNotifier<ItemConstraints> _constraintNotifier;
  final ValueNotifier<LayoutTransform> _transformNotifier =
      ValueNotifier(const LayoutTransform());
  final ValueNotifier<Layout> _layoutNotifier;
  final MutableNotifier<List<CanvasItem>> _childrenNotifier;
  final ValueNotifier<bool> selectedNotifier;
  final ValueNotifier<bool> clipContentNotifier;
  ValueListenable<ItemConstraints> get constraintsListenable =>
      _constraintNotifier;

  bool _isDirty = false;
  BoxConstraints? _lastConstraints;

  CanvasItem({
    Layout layout = const FixedLayout(),
    ItemConstraints constraints = const FixedConstraints(),
    bool selected = false,
    bool clipContent = false,
    List<CanvasItem> children = const [],
    this.debugLabel,
  })  : _layoutNotifier = ValueNotifier(layout),
        _constraintNotifier = ValueNotifier(constraints),
        _childrenNotifier = MutableNotifier(children),
        selectedNotifier = ValueNotifier(selected),
        clipContentNotifier = ValueNotifier(clipContent) {
    for (final child in children) {
      child.attach(this);
    }
    _constraintNotifier.addListener(_handleConstraintChanged);
    _childrenNotifier.addListener(_handleChildrenChanged);
  }

  void attach(CanvasItem parent) {
    assert(_parentNotifier.value == null, 'Item already has a parent');
    _parentNotifier.value = parent;
  }

  void detach(CanvasItem parent) {
    assert(_parentNotifier.value == parent, 'Item is not a child of $parent');
    _parentNotifier.value = null;
  }

  void _handleConstraintChanged() {
    _isDirty = true;
    relayout();
  }

  void _handleChildrenChanged() {
    _isDirty = true;
    relayout();
  }

  void performLayout(BoxConstraints constraints) {
    if (_lastConstraints == constraints) {
      return;
    }
    layout.performLayout(this, constraints);
    _lastConstraints = constraints;
  }

  CanvasItem clone() {
    return CanvasItem(
      layout: layout,
      constraints: constraints,
      selected: selected,
      clipContent: clipContent,
      children: children.map((e) => e.clone()).toList(),
    );
  }

  bool get clipContent => clipContentNotifier.value;
  set clipContent(bool clipContent) => clipContentNotifier.value = clipContent;

  ValueListenable<List<CanvasItem>> get childrenListenable =>
      _childrenNotifier.listenable(
        (value) {
          return List.unmodifiable(value);
        },
      );
  ValueListenable<LayoutTransform> get transformListenable =>
      _transformNotifier;

  /// Visit from root to this item
  LinkedList<CanvasItemEntry> getPathFromRoot(Predicate<CanvasItem> predicate) {
    LinkedList<CanvasItemEntry> path = LinkedList<CanvasItemEntry>();
    CanvasItem? current = this;
    while (current != null && predicate(current)) {
      path.addFirst(CanvasItemEntry(current));
      current = current.parent;
    }
    return path;
  }

  Widget? build(BuildContext context) => null;

  ItemConstraints get constraints => constraintsListenable.value;

  Layout get layout => _layoutNotifier.value;
  set layout(Layout layout) => _layoutNotifier.value = layout;
  ValueListenable<Layout> get layoutListenable => _layoutNotifier;

  List<CanvasItem> get children => List.unmodifiable(_childrenNotifier.value);

  LayoutTransform get transform => transformListenable.value;
  bool get selected => selectedNotifier.value;

  set transform(LayoutTransform transform) {
    transform._debugValidate();
    _transformNotifier.value = transform;
  }

  void addChildren(List<CanvasItem> children) {
    for (final child in children) {
      child.attach(this);
    }
    _childrenNotifier.value.addAll(children);
    _childrenNotifier.notify();
  }

  void removeChildren(List<CanvasItem> children) {
    _childrenNotifier.value.removeWhere((element) {
      if (children.contains(element)) {
        element.detach(this);
        return true;
      }
      return false;
    });
    _childrenNotifier.notify();
  }

  void addChild(CanvasItem child) {
    child.attach(this);
    _childrenNotifier.value.add(child);
    _childrenNotifier.notify();
  }

  void removeChild(CanvasItem child) {
    child.detach(this);
    _childrenNotifier.value.remove(child);
    _childrenNotifier.notify();
  }

  void removeChildAt(int index) {
    var child = children[index];
    child.detach(this);
    _childrenNotifier.value.removeAt(index);
    _childrenNotifier.notify();
  }

  void insertChild(int index, CanvasItem child) {
    child.attach(this);
    _childrenNotifier.value.insert(index, child);
    _childrenNotifier.notify();
  }

  CanvasItem? get parent => _parentNotifier.value;
  ValueListenable<CanvasItem?> get parentListenable => _parentNotifier;

  Matrix4? get parentTransform {
    var parent = this.parent;
    var current = Matrix4.identity();
    while (parent != null) {
      current = parent.transform.toMatrix4() * current;
      parent = parent.parent;
    }
    return current;
  }

  Matrix4? get nonTranslatedParentTransform {
    var parent = this.parent;
    var current = Matrix4.identity();
    while (parent != null) {
      current = parent.transform.toNonTranslatedMatrix4() * current;
      parent = parent.parent;
    }
    return current;
  }

  Matrix4 get globalTransform {
    var transform = this.transform.toMatrix4();
    var parentTransform = this.parentTransform;
    if (parentTransform != null) {
      transform = parentTransform * transform;
    }
    return transform;
  }

  Matrix4 get globalNonTranslatedTransform {
    var transform = this.transform.toNonTranslatedMatrix4();
    var parentTransform = nonTranslatedParentTransform;
    if (parentTransform != null) {
      transform = parentTransform * transform;
    }
    return transform;
  }

  bool get opaque => true;

  set constraints(ItemConstraints layout) {
    _constraintNotifier.value = layout;
  }

  void relayout() {
    if (constraints.constrainedByParent) {
      return;
    }
    // assert(_lastConstraints != null && parent != null,
    //     'No constraints to relayout');
    _isDirty = false;
    // if (parent == null) {
    //   _lastConstraints = const BoxConstraints();
    // }
    layout.performLayout(this, _lastConstraints ?? const BoxConstraints());
    for (final child in children) {
      child.relayout();
    }
  }

  void relayoutParent() {
    var parent = this.parent;
    if (parent != null) {
      parent.relayout();
    }
  }

  CanvasItem get root {
    CanvasItem current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }

  set children(List<CanvasItem> children) {
    var oldChildren = this.children;
    for (final child in oldChildren) {
      if (!children.contains(child)) {
        child.detach(this);
      }
    }
    for (final child in children) {
      if (!oldChildren.contains(child)) {
        child.attach(this);
      }
    }
    _childrenNotifier.value = children;
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
    while (current.isDescendant(target)) {
      visitor(current);
      bool found = false;
      for (final child in current.children) {
        if (child.isDescendant(target)) {
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
    // selection = transform.transformFromParentPolygon(selection);
    selection = transform.toInverseMatrix4().transformPolygon(selection);
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
    // position = transform.transformFromParent(position);
    position = transform.toInverseMatrix4().transformPoint(position);
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

  bool isDescendant(CanvasItem item) {
    if (item == this) {
      return true;
    }
    for (final child in children) {
      if (child.isDescendant(item)) {
        return true;
      }
    }
    return false;
  }

  void visitWithTransform(
      void Function(CanvasItem item, Matrix4? parentTransform) visitor,
      {bool rootSelectionOnly = false,
      Matrix4? parentTransform}) {
    Matrix4 transform = parentTransform == null
        ? this.transform.toMatrix4()
        : parentTransform * this.transform.toMatrix4();
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

  void visitSnappingPoints(
      void Function(CanvasItem item, SnappingPoint snappingPoint) visitor,
      SnappingToggle snappingToggle,
      [Matrix4? parentTransform]) {
    Matrix4 currentTransform = parentTransform == null
        ? transform.toMatrix4()
        : parentTransform * transform.toMatrix4();
    // TODO: rework this
    // if (opaque) {
    //   var scaledSize = currentTransform.scaledSize;
    //   if (snappingToggle.topLeft) {
    //     Offset topLeft = currentTransform.offset;
    //     visitor(this,
    //         SnappingPoint(position: topLeft, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.topRight) {
    //     Offset topRight = currentTransform.offset +
    //         rotatePoint(Offset(scaledSize.width, 0), currentTransform.rotation);
    //     visitor(
    //         this,
    //         SnappingPoint(
    //             position: topRight, angle: currentTransform.rotation));
    //   }
    //   Offset bottomLeft = currentTransform.offset +
    //       rotatePoint(Offset(0, scaledSize.height), currentTransform.rotation);
    //   if (snappingToggle.bottomLeft) {
    //     visitor(
    //         this,
    //         SnappingPoint(
    //             position: bottomLeft, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.bottomRight) {
    //     Offset bottomRight = currentTransform.offset +
    //         rotatePoint(Offset(scaledSize.width, scaledSize.height),
    //             currentTransform.rotation);
    //     visitor(
    //         this,
    //         SnappingPoint(
    //             position: bottomRight, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.center) {
    //     Offset center = currentTransform.offset +
    //         rotatePoint(Offset(scaledSize.width / 2, scaledSize.height / 2),
    //             currentTransform.rotation);
    //     visitor(this,
    //         SnappingPoint(position: center, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.top) {
    //     Offset top = currentTransform.offset +
    //         rotatePoint(
    //             Offset(scaledSize.width / 2, 0), currentTransform.rotation);
    //     visitor(this,
    //         SnappingPoint(position: top, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.left) {
    //     Offset left = currentTransform.offset +
    //         rotatePoint(
    //             Offset(0, scaledSize.height / 2), currentTransform.rotation);
    //     visitor(this,
    //         SnappingPoint(position: left, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.right) {
    //     Offset right = currentTransform.offset +
    //         rotatePoint(Offset(scaledSize.width, scaledSize.height / 2),
    //             currentTransform.rotation);
    //     visitor(this,
    //         SnappingPoint(position: right, angle: currentTransform.rotation));
    //   }
    //   if (snappingToggle.bottom) {
    //     Offset bottom = currentTransform.offset +
    //         rotatePoint(Offset(scaledSize.width / 2, scaledSize.height),
    //             currentTransform.rotation);
    //     visitor(this,
    //         SnappingPoint(position: bottom, angle: currentTransform.rotation));
    //   }
    // }
    // for (final child in children) {
    //   child.visitSnappingPoints(visitor, snappingToggle, currentTransform);
    // }
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
    // return globalTransform.transformToParentPolygon(boundingBox);
    return globalTransform.transformPolygon(boundingBox);
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
    // return globalTransform.transformToParent(position);
    return globalTransform.transformPoint(position);
  }

  Offset toLocal(Offset position) {
    // return globalTransform.transformFromParent(position);
    return Matrix4.inverted(globalTransform).transformPoint(position);
  }

  Offset toGlobalDelta(Offset delta) {
    return globalTransform.removeTranslation().transformPoint(delta);
  }

  Offset toLocalDelta(Offset delta) {
    return Matrix4.inverted(globalTransform.removeTranslation())
        .transformPoint(delta);
  }

  @override
  String toString() {
    return '$runtimeType(${debugLabel ?? '#$hashCode'})';
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
    super.children = const [],
  });

  final ValueNotifier<bool> _selectedNotifier = _FinalValueNotifier(true);

  final ValueNotifier<bool> _clipContentNotifier = _FinalValueNotifier(false);

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

  @override
  CanvasItem clone() {
    throw UnimplementedError();
  }
}

class BoxCanvasItem extends CanvasItem {
  final Widget? decoration;
  BoxCanvasItem({
    this.decoration,
    super.children,
    super.constraints,
    super.debugLabel,
    super.selected,
    super.clipContent,
    super.layout,
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
