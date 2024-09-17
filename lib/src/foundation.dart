import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

Offset _rotate(Offset point, double angle) {
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    point.dx * cosA - point.dy * sinA,
    point.dx * sinA + point.dy * cosA,
  );
}

class CanvasTransform {
  final Offset offset;
  final Size scale;
  final double rotation;
  final Size size;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.scale = const Size(1.0, 1.0),
    this.rotation = 0.0,
    this.size = Size.zero,
  });

  CanvasTransform copyWith({
    Offset? offset,
    Size? scale,
    double? rotation,
    Alignment? alignment,
    Size? size,
  }) {
    return CanvasTransform(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      size: size ?? this.size,
    );
  }

  Matrix4 computeMatrix(CanvasItemNode node) {
    final matrix = Matrix4.identity();
    matrix.translate(offset.dx, offset.dy);
    matrix.rotateZ(rotation);
    matrix.scale(scale.width, scale.height);
    return matrix;
  }

  CanvasTransform drag(Offset delta) {
    delta = delta.scaleBySize(scale);
    delta = delta.rotate(rotation);
    return copyWith(offset: offset + delta);
  }

  CanvasTransform flipHorizontal() {
    return copyWith(scale: Size(-scale.width, scale.height));
  }

  CanvasTransform flipVertical() {
    return copyWith(scale: Size(scale.width, -scale.height));
  }

  CanvasTransform flip() {
    return copyWith(scale: Size(-scale.width, -scale.height));
  }

  CanvasTransform resizeTopLeft(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeTop(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeTopRight(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeRight(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottomRight(Offset delta,
      [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottom(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottomLeft(Offset delta,
      [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform resizeLeft(Offset delta, [Offset origin = Offset.zero]) {
    // TODO
    return this;
  }

  CanvasTransform rotate(double angle, [Offset origin = Offset.zero]) {
    return copyWith(rotation: rotation + angle);
  }

  CanvasTransform scaleTopLeft(Offset delta) {
    // TODO
    return this;
  }

  @override
  String toString() {
    return 'CanvasTransform{offset: $offset, scale: $scale, rotation: $rotation, size: $size}';
  }
}

extension SizeExtension on Size {
  Size abs() {
    return Size(width.abs(), height.abs());
  }
}

extension OffsetExtension on Offset {
  Offset scaleBySize(Size scale) {
    return Offset(dx * scale.width, dy * scale.height);
  }

  Offset divideBySize(Size scale) {
    return Offset(dx / scale.width, dy / scale.height);
  }

  Offset rotate(double angle) {
    return _rotate(this, angle);
  }

  Offset onlyX() {
    return Offset(dx, 0);
  }

  Offset onlyY() {
    return Offset(0, dy);
  }
}

enum TransformControlMode {
  /// Hide the control, but can still be dragged
  hide,

  /// Show the control
  show,

  /// Hide the control, but can still be dragged and has zoom control
  viewport,
}

class TransformControlFlag {
  final bool canMove;
  final bool canRotate;
  final bool canResize;
  final bool canScale;

  const TransformControlFlag({
    this.canMove = true,
    this.canRotate = true,
    this.canResize = true,
    this.canScale = true,
  });

  TransformControlFlag copyWith({
    bool? canMove,
    bool? canRotate,
    bool? canResize,
    bool? canScale,
  }) {
    return TransformControlFlag(
      canMove: canMove ?? this.canMove,
      canRotate: canRotate ?? this.canRotate,
      canResize: canResize ?? this.canResize,
      canScale: canScale ?? this.canScale,
    );
  }
}

class CanvasItem {
  final ValueNotifier<CanvasTransform> transformNotifier;
  final ValueNotifier<Widget?> widgetNotifier;
  final ValueNotifier<TransformControlMode> transformControlModeNotifier;
  final ValueNotifier<bool> selectedNotifier;
  final ValueNotifier<TransformControlFlag> controlFlagNotifier;
  final ValueNotifier<UnaryOpertor<CanvasTransform>?> onTransformingNotifier;
  final ValueNotifier<List<CanvasItem>> childrenNotifier;

  CanvasItem({
    required CanvasTransform transform,
    Widget? widget,
    TransformControlMode transformControlMode = TransformControlMode.hide,
    TransformControlFlag controlFlag = const TransformControlFlag(),
    CanvasTransform Function(CanvasTransform, CanvasTransform)? onTransforming,
    void Function(CanvasTransform)? onTransformed,
    List<CanvasItem> children = const [],
    bool selected = false,
  })  : widgetNotifier = ValueNotifier(widget),
        onTransformingNotifier = ValueNotifier(onTransforming),
        childrenNotifier = ValueNotifier(children),
        controlFlagNotifier = ValueNotifier(controlFlag),
        transformControlModeNotifier = ValueNotifier(transformControlMode),
        selectedNotifier = ValueNotifier(selected),
        transformNotifier = ValueNotifier(transform);

  void dispatchTransformChanging(CanvasTransform transform) {
    transformNotifier.value = onTransformingNotifier.value
            ?.call(transform, transformNotifier.value) ??
        transform;
  }

  CanvasItemNode toNode([CanvasItemNode? parent]) {
    return CanvasItemNode(item: this, parent: parent);
  }

  CanvasTransform get transform => transformNotifier.value;
  set transform(CanvasTransform value) {
    transformNotifier.value = value;
  }

  bool get selected => selectedNotifier.value;
  set selected(bool value) {
    selectedNotifier.value = value;
  }

  Widget? get widget => widgetNotifier.value;
  set widget(Widget? value) {
    widgetNotifier.value = value;
  }

  TransformControlMode get transformControlMode =>
      transformControlModeNotifier.value;
  set transformControlMode(TransformControlMode value) {
    transformControlModeNotifier.value = value;
  }

  TransformControlFlag get controlFlag => controlFlagNotifier.value;
  set controlFlag(TransformControlFlag value) {
    controlFlagNotifier.value = value;
  }

  CanvasTransform Function(CanvasTransform, CanvasTransform)?
      get onTransforming => onTransformingNotifier.value;
  set onTransforming(
      CanvasTransform Function(CanvasTransform, CanvasTransform)? value) {
    onTransformingNotifier.value = value;
  }

  List<CanvasItem> get children => childrenNotifier.value;
  set children(List<CanvasItem> value) {
    childrenNotifier.value = value;
  }

  @override
  String toString() {
    return 'CanvasItem{transform: $transform, widget: $widget, transformControlMode: $transformControlMode, controlFlag: $controlFlag, onTransforming: $onTransforming, children: $children}';
  }
}

class CanvasItemNode {
  final CanvasItem item;
  late List<CanvasItemNode> _children;
  final CanvasItemNode? parent;

  CanvasItemNode({
    required this.item,
    this.parent,
  }) {
    item.childrenNotifier.addListener(_onChildrenChanged);
    _children = item.children.map((child) => child.toNode(this)).toList();
  }

  void _onChildrenChanged() {
    _children = item.children.map((child) => child.toNode(this)).toList();
  }

  List<CanvasItemNode> get children => _children;

  void visit(void Function(CanvasItemNode node) visitor) {
    visitor(this);
    visitChildren(visitor);
  }

  void visitChildren(void Function(CanvasItemNode node) visitor) {
    for (final child in _children) {
      child.visit(visitor);
    }
  }

  void visitFromRoot(void Function(CanvasItemNode node) visitor) {
    if (parent != null) {
      parent!.visitFromRoot(visitor);
    }
    visitor(this);
  }

  void visitToRoot(void Function(CanvasItemNode node) visitor) {
    visitor(this);
    if (parent != null) {
      parent!.visitToRoot(visitor);
    }
  }

  void dispose() {
    item.childrenNotifier.removeListener(_onChildrenChanged);
    for (final child in _children) {
      child.dispose();
    }
  }

  @override
  String toString() {
    return 'CanvasItemNode{item: $item, children: $_children}';
  }
}

class CanvasViewport {
  final CanvasItemNode _root;

  CanvasViewport({
    Offset offset = Offset.zero,
    double zoom = 1.0,
    List<CanvasItem> items = const [],
  }) : _root = CanvasItem(
                transform: CanvasTransform(
                  offset: offset,
                  scale: Size(zoom, zoom),
                ),
                children: items)
            .toNode();

  ValueNotifier<CanvasTransform> get transformNotifier =>
      _root.item.transformNotifier;

  CanvasTransform get transform => _root.item.transform;
  set transform(CanvasTransform value) {
    _root.item.transform = value;
  }

  CanvasItemNode get rootNode => _root;

  void dispose() {
    _root.dispose();
  }
}
