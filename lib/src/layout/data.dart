import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasLayoutData {
  final Offset? shear;
  final Offset? scale;
  final BoxConstraints? constraints;

  const CanvasLayoutData({
    this.shear,
    this.scale,
    this.constraints,
  });

  CanvasLayoutData copyWith({
    ValueGetter<Offset?>? shear,
    ValueGetter<Offset?>? scale,
    ValueGetter<BoxConstraints?>? constraints,
  });

  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasParentState targetParent, Matrix4 transform) {
    return this;
  }

  CanvasLayoutData handleLayoutChange(
      CanvasItemState item, CanvasLayout layout) {
    return this;
  }

  Matrix4 get transform {
    Matrix4 matrix = Matrix4.identity();
    if (shear != null) {
      matrix = matrix * computeShearMatrix(shear!);
    }
    if (scale != null) {
      matrix = matrix * Matrix4.diagonal3Values(scale!.dx, scale!.dy, 1);
    }
    return matrix;
  }

  CanvasLayoutData drag(CanvasItemState item, Delta delta) {
    return this;
  }
}

class ParentLayoutData extends CanvasLayoutData {
  final Offset offset;
  final Size size;
  const ParentLayoutData({
    super.shear,
    super.scale,
    super.constraints,
    this.offset = Offset.zero,
    this.size = Size.zero,
  });

  @override
  CanvasLayoutData copyWith({
    ValueGetter<Offset?>? shear,
    ValueGetter<Offset?>? scale,
    ValueGetter<BoxConstraints?>? constraints,
    ValueGetter<Offset>? offset,
    ValueGetter<Size>? size,
  }) {
    return ParentLayoutData(
      shear: shear != null ? shear() : this.shear,
      scale: scale != null ? scale() : this.scale,
      constraints: constraints != null ? constraints() : this.constraints,
      offset: offset != null ? offset() : this.offset,
      size: size != null ? size() : this.size,
    );
  }

  @override
  CanvasLayoutData drag(CanvasItemState item, Delta delta) {
    return copyWith(
      offset: () => offset + delta.delta,
    );
  }

  @override
  String toString() {
    return 'ParentLayoutData{offset: $offset, size: $size, shear: $shear, scale: $scale, constraints: $constraints}';
  }
}

class AbsoluteLayoutData extends CanvasLayoutData {
  final Position? top;
  final Position? left;
  final Position? right;
  final Position? bottom;
  final ConstrainedSizeConstraint? width;
  final ConstrainedSizeConstraint? height;
  final bool scaleHorizontal;
  final bool scaleVertical;

  const AbsoluteLayoutData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width,
    this.height,
    super.shear,
    super.scale,
    super.constraints,
    this.scaleHorizontal = false,
    this.scaleVertical = false,
  });

  @override
  CanvasLayoutData drag(CanvasItemState item, Delta delta) {
    return copyWith(
      top: () => top?.shift(delta.delta.dy, item.size.height),
      left: () => left?.shift(delta.delta.dx, item.size.width),
      right: () => right?.shift(-delta.delta.dx, item.size.width),
      bottom: () => bottom?.shift(-delta.delta.dy, item.size.height),
    );
  }

  @override
  CanvasLayoutData handleLayoutChange(
      CanvasItemState item, CanvasLayout layout) {
    if (layout is FlexLayout) {
      return FlexibleLayoutData(
        width: FixedSizeConstraint(item.size.width),
        height: FixedSizeConstraint(item.size.height),
        shear: shear,
        scale: scale,
        constraints: constraints,
      );
    }
    return super.handleLayoutChange(item, layout);
  }

  @override
  CanvasLayoutData copyWith({
    ValueGetter<Offset?>? shear,
    ValueGetter<Offset?>? scale,
    ValueGetter<BoxConstraints?>? constraints,
    ValueGetter<Position?>? top,
    ValueGetter<Position?>? left,
    ValueGetter<Position?>? right,
    ValueGetter<Position?>? bottom,
    ValueGetter<ConstrainedSizeConstraint?>? width,
    ValueGetter<ConstrainedSizeConstraint?>? height,
    ValueGetter<bool>? scaleHorizontal,
    ValueGetter<bool>? scaleVertical,
  }) {
    return AbsoluteLayoutData(
      top: top != null ? top() : this.top,
      left: left != null ? left() : this.left,
      right: right != null ? right() : this.right,
      bottom: bottom != null ? bottom() : this.bottom,
      width: width != null ? width() : this.width,
      height: height != null ? height() : this.height,
      scaleHorizontal:
          scaleHorizontal != null ? scaleHorizontal() : this.scaleHorizontal,
      scaleVertical:
          scaleVertical != null ? scaleVertical() : this.scaleVertical,
      shear: shear != null ? shear() : this.shear,
      scale: scale != null ? scale() : this.scale,
      constraints: constraints != null ? constraints() : this.constraints,
    );
  }

  @override
  String toString() {
    return 'AbsoluteLayoutData{top: $top, left: $left, right: $right, bottom: $bottom, width: $width, height: $height, shear: $shear, scale: $scale, constraints: $constraints}';
  }
}

class FlexibleLayoutData extends CanvasLayoutData {
  final SizeConstraint width;
  final SizeConstraint height;

  const FlexibleLayoutData({
    this.width = const FixedSizeConstraint(0),
    this.height = const FixedSizeConstraint(0),
    super.shear,
    super.scale,
    super.constraints,
  });

  @override
  CanvasLayoutData handleLayoutChange(
      CanvasItemState item, CanvasLayout layout) {
    if (item is FixedLayout) {
      return AbsoluteLayoutData(
        top: AbsolutePosition(item.parentData.position.dy),
        left: AbsolutePosition(item.parentData.position.dx),
        width: FixedSizeConstraint(item.size.width),
        height: FixedSizeConstraint(item.size.height),
        shear: shear,
        scale: scale,
        constraints: constraints,
      );
    }
    return super.handleLayoutChange(item, layout);
  }

  @override
  CanvasLayoutData copyWith({
    ValueGetter<Offset?>? shear,
    ValueGetter<Offset?>? scale,
    ValueGetter<BoxConstraints?>? constraints,
    ValueGetter<SizeConstraint>? width,
    ValueGetter<SizeConstraint>? height,
  }) {
    return FlexibleLayoutData(
      width: width != null ? width() : this.width,
      height: height != null ? height() : this.height,
      shear: shear != null ? shear() : this.shear,
      scale: scale != null ? scale() : this.scale,
      constraints: constraints != null ? constraints() : this.constraints,
    );
  }
}

class PathLayoutData extends CanvasLayoutData {
  final double index;
  final bool rotateAlongPath;
  final Offset offset;
  final Alignment alignment;

  const PathLayoutData({
    required this.index,
    required this.rotateAlongPath,
    required this.offset,
    required this.alignment,
    super.shear,
    super.scale,
    super.constraints,
  });

  @override
  CanvasLayoutData copyWith({
    ValueGetter<Offset?>? shear,
    ValueGetter<Offset?>? scale,
    ValueGetter<BoxConstraints?>? constraints,
    ValueGetter<double>? index,
    ValueGetter<bool>? rotateAlongPath,
    ValueGetter<Offset>? offset,
    ValueGetter<Alignment>? alignment,
  }) {
    return PathLayoutData(
      index: index != null ? index() : this.index,
      rotateAlongPath:
          rotateAlongPath != null ? rotateAlongPath() : this.rotateAlongPath,
      offset: offset != null ? offset() : this.offset,
      alignment: alignment != null ? alignment() : this.alignment,
      shear: shear != null ? shear() : this.shear,
      scale: scale != null ? scale() : this.scale,
      constraints: constraints != null ? constraints() : this.constraints,
    );
  }
}
