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

abstract class SizeConstraint {
  const SizeConstraint._();

  const factory SizeConstraint.box(double min, double max) = _BoxSizeConstraint;
  const factory SizeConstraint.tight(double value) = _BoxSizeConstraint.tight;
  const factory SizeConstraint.hugTight(double value) = _HugConstraint.tight;
  const factory SizeConstraint.fillTight(double value) = _FillConstraint.tight;
  const factory SizeConstraint.hugLoose() = _HugConstraint.loose;
  const factory SizeConstraint.fillLoose() = _FillConstraint.loose;
  const factory SizeConstraint.hug(double min, double max) = _HugConstraint;
  const factory SizeConstraint.fill(double min, double max) = _FillConstraint;
}

class _BoxSizeConstraint extends SizeConstraint {
  final double min;
  final double max;

  const _BoxSizeConstraint(this.min, this.max) : super._();
  const _BoxSizeConstraint.tight(double value)
      : min = value,
        max = value,
        super._();
}

class _HugConstraint extends _BoxSizeConstraint {
  const _HugConstraint(super.min, super.max);
  const _HugConstraint.tight(double value) : super.tight(value);
  const _HugConstraint.loose() : super(0, double.infinity);
}

class _FillConstraint extends _BoxSizeConstraint {
  const _FillConstraint(super.min, super.max);
  const _FillConstraint.tight(double value) : super.tight(value);
  const _FillConstraint.loose() : super(0, double.infinity);
}

abstract base class ContainerTransform extends CanvasTransform {
  final EdgeInsets padding;
  final Alignment alignment;
  final Anchor? anchor;
  const ContainerTransform({
    super.offset,
    super.scale,
    super.rotation,
    super.size,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.anchor,
  });
}

class Anchor {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const Anchor({
    this.left,
    this.top,
    this.right,
    this.bottom,
  })  : assert(left != null || right != null, 'left or right must be set'),
        assert(top != null || bottom != null, 'top or bottom must be set'),
        assert(left == null || right == null,
            'left and right cannot be set at the same time'),
        assert(top == null || bottom == null,
            'top and bottom cannot be set at the same time');
}

final class FlexContainerTransform extends ContainerTransform {
  final AxisDirection direction;
  final double gap;
  const FlexContainerTransform({
    super.offset,
    super.scale,
    super.rotation,
    super.size,
    super.alignment,
    super.padding,
    required this.direction,
    this.gap = 0.0,
  });
}

class CanvasTransform {
  final Offset offset;
  final Offset scale;
  final double rotation;
  final Size size;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.scale = const Offset(1.0, 1.0),
    this.rotation = 0.0,
    this.size = Size.zero,
  });

  CanvasTransform copyWith({
    Offset? offset,
    Offset? scale,
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

  CanvasTransform drag(CanvasItemNode node, Offset delta) {
    if (delta == Offset.zero) return this;
    return copyWith(offset: offset + delta);
  }

  CanvasTransform resize(CanvasItemNode node, Offset delta, Alignment handle,
      [Alignment? alignment]) {
    if (handle == alignment || delta == Offset.zero) return this;
    alignment ??= handle * -1;
    return this;
  }

  CanvasTransform rotate(CanvasItemNode node, double angle,
      [Alignment alignment = Alignment.center]) {
    if (angle == 0) return this;
    return copyWith(rotation: rotation + angle);
  }

  CanvasTransform scaleTransform(
      CanvasItemNode node, Offset delta, Alignment handle,
      [Alignment? alignment]) {
    if (handle == alignment || delta == Offset.zero) return this;
    alignment ??= handle * -1;
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
  final ValueNotifier<Matrix4> transformControlMatrixNotifier =
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
                  scale: Offset(zoom, zoom),
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
