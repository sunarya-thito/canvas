import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class IntrinsicComputation {
  final double? minIntrinsicWidth;
  final double? maxIntrinsicWidth;
  final double? minIntrinsicHeight;
  final double? maxIntrinsicHeight;

  const IntrinsicComputation({
    this.minIntrinsicWidth,
    this.maxIntrinsicWidth,
    this.minIntrinsicHeight,
    this.maxIntrinsicHeight,
  });
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

  void performLayout(CanvasItemNode node) {
    final matrix = _computeMatrix();
    node.matrix = matrix;
    node.size = size;
    for (final child in node.children) {
      child.item.transform.performLayout(child);
    }
  }

  Matrix4 _computeMatrix() {
    final matrix = Matrix4.identity();
    matrix.translate(offset.dx, offset.dy);
    matrix.rotateZ(rotation);
    return matrix;
  }

  CanvasTransform drag(Offset delta) {
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

  CanvasTransform resizeTopLeft(Offset delta,
      [Alignment alignment = Alignment.bottomRight]) {
    final align = _alignmentToOffset(alignment);
    final newOffset = offset + delta;
    return copyWith(offset: newOffset, size: size);
  }

  CanvasTransform resizeTop(Offset delta,
      [Alignment alignment = Alignment.bottomCenter]) {
    // TODO
    return this;
  }

  CanvasTransform resizeTopRight(Offset delta,
      [Alignment alignment = Alignment.bottomLeft]) {
    // TODO
    return this;
  }

  CanvasTransform resizeRight(Offset delta,
      [Alignment alignment = Alignment.centerLeft]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottomRight(Offset delta,
      [Alignment alignment = Alignment.topLeft]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottom(Offset delta,
      [Alignment alignment = Alignment.topCenter]) {
    // TODO
    return this;
  }

  CanvasTransform resizeBottomLeft(Offset delta,
      [Alignment alignment = Alignment.topRight]) {
    // TODO
    return this;
  }

  CanvasTransform resizeLeft(Offset delta,
      [Alignment alignment = Alignment.centerRight]) {
    // TODO
    return this;
  }

  CanvasTransform rotate(double angle,
      [Alignment alignment = Alignment.center]) {
    return copyWith(rotation: rotation + angle);
  }

  CanvasTransform scaleTopLeft(Offset delta,
      [Alignment alignment = Alignment.bottomRight]) {
    // TODO
    return this;
  }

  CanvasTransform scaleTop(Offset delta,
      [Alignment alignment = Alignment.bottomCenter]) {
    // TODO
    return this;
  }

  CanvasTransform scaleTopRight(Offset delta,
      [Alignment alignment = Alignment.bottomLeft]) {
    // TODO
    return this;
  }

  CanvasTransform scaleRight(Offset delta,
      [Alignment alignment = Alignment.centerLeft]) {
    // TODO
    return this;
  }

  CanvasTransform scaleBottomRight(Offset delta,
      [Alignment alignment = Alignment.topLeft]) {
    // TODO
    return this;
  }

  CanvasTransform scaleBottom(Offset delta,
      [Alignment alignment = Alignment.topCenter]) {
    // TODO
    return this;
  }

  CanvasTransform scaleBottomLeft(Offset delta,
      [Alignment alignment = Alignment.topRight]) {
    // TODO
    return this;
  }

  CanvasTransform scaleLeft(Offset delta,
      [Alignment alignment = Alignment.centerRight]) {
    // TODO
    return this;
  }

  @override
  String toString() {
    return 'CanvasTransform{offset: $offset, scale: $scale, rotation: $rotation, size: $size}';
  }

  bool get parentCanLayout => true;
}

double _divideOrZero(double a, double b) {
  if (b == 0) {
    return 0;
  }
  return a / b;
}

extension SizeExtension on Size {
  Size abs() {
    return Size(width.abs(), height.abs());
  }
}

extension OffsetExtension on Offset {
  Vector3 get vector3 {
    return Vector3(dx, dy, 0);
  }

  Offset onlyX() {
    return Offset(dx, 0);
  }

  Offset onlyY() {
    return Offset(0, dy);
  }
}

extension Vector3Extension on Vector3 {
  Offset get offset {
    return Offset(x, y);
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

class TextCanvasItem extends CanvasItem {
  final ValueNotifier<InlineSpan> textNotifier;
  final ValueNotifier<TextDirection> textDirectionNotifier;

  TextCanvasItem({
    required super.transform,
    super.transformControlMode = TransformControlMode.show,
    super.controlFlag = const TransformControlFlag(),
    super.onTransforming,
    super.children = const [],
    super.selected = false,
    super.onTransformed,
    InlineSpan text = const TextSpan(),
    TextDirection textDirection = TextDirection.ltr,
  })  : textNotifier = ValueNotifier(text),
        textDirectionNotifier = ValueNotifier(textDirection),
        super();

  @override
  IntrinsicComputation computeIntrinsic(
    CanvasItemNode node, {
    bool minWidth = false,
    bool maxWidth = false,
    bool minHeight = false,
    bool maxHeight = false,
    double? width,
    double? height,
  }) {
    TextPainter painter = TextPainter(
      text: textNotifier.value,
      textDirection: textDirectionNotifier.value,
    );
    painter.layout(minWidth: width ?? 0, maxWidth: width ?? double.infinity);
    return IntrinsicComputation(
      minIntrinsicWidth: minWidth ? painter.width : null,
      maxIntrinsicWidth: maxWidth ? painter.width : null,
      minIntrinsicHeight: minHeight ? painter.height : null,
      maxIntrinsicHeight: maxHeight ? painter.height : null,
    );
  }

  @override
  void addListener(VoidCallback listener) {
    textNotifier.addListener(listener);
    textDirectionNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    textNotifier.removeListener(listener);
    textDirectionNotifier.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textNotifier.value,
      textDirection: textDirectionNotifier.value,
    );
  }
}

class BoxCanvasItem extends CanvasItem {
  final ValueNotifier<Widget> widgetNotifier;

  BoxCanvasItem({
    required super.transform,
    super.transformControlMode = TransformControlMode.show,
    super.controlFlag = const TransformControlFlag(),
    super.onTransforming,
    super.children = const [],
    super.selected = false,
    super.onTransformed,
    Widget? widget,
  })  : widgetNotifier = ValueNotifier(widget ?? const SizedBox()),
        super();

  @override
  Widget build(BuildContext context) {
    return widgetNotifier.value;
  }

  @override
  void addListener(VoidCallback listener) {
    widgetNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    widgetNotifier.removeListener(listener);
  }
}

class _RootCanvasItem extends CanvasItem {
  _RootCanvasItem({
    required super.transform,
    super.children = const [],
  }) : super(
          transformControlMode: TransformControlMode.viewport,
        );

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

abstract class CanvasItem implements Listenable {
  final ValueNotifier<CanvasTransform> transformNotifier;
  final ValueNotifier<TransformControlMode> transformControlModeNotifier;
  final ValueNotifier<bool> selectedNotifier;
  final ValueNotifier<TransformControlFlag> controlFlagNotifier;
  final ValueNotifier<UnaryOpertor<CanvasTransform>?> onTransformingNotifier;
  final ValueNotifier<List<CanvasItem>> childrenNotifier;

  CanvasItem({
    required CanvasTransform transform,
    TransformControlMode transformControlMode = TransformControlMode.show,
    TransformControlFlag controlFlag = const TransformControlFlag(),
    CanvasTransform Function(CanvasTransform, CanvasTransform)? onTransforming,
    void Function(CanvasTransform)? onTransformed,
    List<CanvasItem> children = const [],
    bool selected = false,
  })  : onTransformingNotifier = ValueNotifier(onTransforming),
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

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  Widget build(BuildContext context);

  CanvasItemNode toNode([CanvasItemNode? parent]) {
    return CanvasItemNode(item: this, parent: parent);
  }

  IntrinsicComputation computeIntrinsic(CanvasItemNode node,
      {bool minWidth = false,
      bool maxWidth = false,
      bool minHeight = false,
      bool maxHeight = false}) {
    return IntrinsicComputation(
      minIntrinsicWidth: minWidth ? transform.size.width : null,
      maxIntrinsicWidth: maxWidth ? transform.size.width : null,
      minIntrinsicHeight: minHeight ? transform.size.height : null,
      maxIntrinsicHeight: maxHeight ? transform.size.height : null,
    );
  }

  CanvasTransform get transform => transformNotifier.value;
  set transform(CanvasTransform value) {
    transformNotifier.value = value;
  }

  bool get selected => selectedNotifier.value;
  set selected(bool value) {
    selectedNotifier.value = value;
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
}

class CanvasItemNode {
  CanvasItem _item;
  late List<CanvasItemNode> _children;
  CanvasItemNode? _parent;
  final ValueNotifier<Matrix4> matrixNotifier =
      ValueNotifier(Matrix4.identity());
  final ValueNotifier<Size> sizeNotifier = ValueNotifier(Size.zero);

  CanvasItemNode({
    required CanvasItem item,
    CanvasItemNode? parent,
  })  : _item = item,
        _parent = parent {
    _onChildrenChanged();
    _relayout();
  }

  CanvasItem get item => _item;
  CanvasItemNode? get parent => _parent;

  void initState() {
    item.childrenNotifier.addListener(_onChildrenChanged);
    item.transformNotifier.addListener(_onTransformChanged);
  }

  CanvasTransform get transform => item.transform;
  set transform(CanvasTransform value) {
    item.transform = value;
  }

  void _onTransformChanged() {
    item.transform.performLayout(this);
  }

  Matrix4 get matrix => matrixNotifier.value;
  set matrix(Matrix4 value) {
    matrixNotifier.value = value;
  }

  Size get size => sizeNotifier.value;
  set size(Size value) {
    sizeNotifier.value = value;
  }

  void _relayout() {
    item.transform.performLayout(this);
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
    item.transformNotifier.removeListener(_onTransformChanged);
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
  }) : _root = _RootCanvasItem(
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

Offset _alignmentToOffset(Alignment alignment) {
  // alignment is a double from -1 to 1
  // convert it to a double from 0 to 1
  final x = (alignment.x + 1) / 2;
  final y = (alignment.y + 1) / 2;
  return Offset(x, y);
}
