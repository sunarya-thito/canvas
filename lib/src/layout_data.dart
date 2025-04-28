import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasLayoutData {
  factory CanvasLayoutData.fromJson(Map<String, Object?> json) {
    String type = json.getString('type') ?? 'absolute';
    switch (type) {
      case 'absolute':
        return AbsoluteLayoutData.fromJson(json);
      case 'fixed':
        return FixedLayoutData.fromJson(json);
      case 'flex':
        return FlexLayoutData.fromJson(json);
      default:
        throw ArgumentError(
            'Unknown layout type: $type. Supported types are: absolute, fixed, flex.');
    }
  }

  final Offset? shear;

  // i don't think there should be a scale
  // even though there is something called
  // scale tool, it is used to scale the entire thing
  // including the size, the font size, the border width,
  // etc. Also, scale tool uses uniform scale.

  // HOWEVER, scale is needed to flip the item horizontally and/or vertically
  final Offset? scale;

  const CanvasLayoutData({
    this.shear,
    this.scale,
  });

  CanvasLayoutData withShear(Offset shear);
  CanvasLayoutData withScale(Offset scale);

  Map<String, Object?> toJson();

  bool get doesAffectParentLayout => true;

  // dropTarget is local to the target
  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget);

  BoxConstraints reduceConstraints(
      CanvasItemState item, BoxConstraints constraints) {
    var smallest = constraints.smallestAllowNegative;
    var biggest = constraints.biggestAllowNegative;
    if (smallest == biggest) {
      return BoxConstraints.tight(
          computeElementSize(smallest, computeElementTransform(smallest)));
    }
    smallest = computeElementSize(smallest, computeElementTransform(smallest));
    biggest = computeElementSize(biggest, computeElementTransform(biggest));
    return BoxConstraints(
      minWidth: smallest.width,
      minHeight: smallest.height,
      maxWidth: biggest.width,
      maxHeight: biggest.height,
    );
  }

  Size computeElementSize(Size boundingBoxSize, Matrix4 elementTransform) {
    return computeFittingSizeFromMatrix(
        matrix: elementTransform,
        boundingBoxWidth: boundingBoxSize.width,
        boundingBoxHeight: boundingBoxSize.height);
  }

  Matrix4 computeElementTransform(Size boundingBoxSize) {
    return computeLocalElementTransform(
      boundingBoxSize: boundingBoxSize,
      shear: shear,
      scale: scale,
    );
  }

  static Matrix4 computeLocalElementTransform(
      {Size boundingBoxSize = Size.zero, Offset? shear, Offset? scale}) {
    Matrix4 transform = Matrix4.identity();
    if (shear != null) {
      transform *= computeShearMatrix(
        shear.dx,
        shear.dy,
        size: boundingBoxSize,
        alignment: Alignment.center,
      );
    }
    if (scale != null) {
      transform.scale(scale.dx, scale.dy);
    }
    return transform;
  }

  static Matrix4 computeAdjustmentTransform(
      Size boundingBoxSize, Size innerSize) {
    Matrix4 transform = Matrix4.identity();
    double dx = (boundingBoxSize.width - innerSize.width) / 2;
    double dy = (boundingBoxSize.height - innerSize.height) / 2;
    transform.translate(dx, dy);
    return transform;
  }

  CanvasLayoutData drag(Offset delta) => this;

  CanvasLayoutData rotate(CanvasItemState item, double newRotation) {
    return skew(item, Rotation(newRotation));
  }

  CanvasLayoutData skew(CanvasItemState item, Offset shear) {
    var shearDelta = shear - (this.shear ?? Offset.zero);
    var size = item.size; // bounding box
    var transform = computeLocalElementTransform(
      shear: shearDelta,
      scale: scale,
    );
    var newBoundingBox =
        computeBoundingBoxFromMatrix(matrix: transform, originalSize: size);
    var deltaWidth = newBoundingBox.width - size.width;
    var deltaHeight = newBoundingBox.height - size.height;
    var halfDeltaWidth = deltaWidth / 2;
    var halfDeltaHeight = deltaHeight / 2;
    print('${shearToString(shearDelta)} $size -> $newBoundingBox');
    return withShear(shear).handleResize(
      item,
      Offset(-halfDeltaWidth, -halfDeltaHeight),
      Offset(deltaWidth, deltaHeight),
    );
  }

  CanvasLayoutData handleResize(
          CanvasItemState item, Offset positionDelta, Offset sizeDelta) =>
      this;
  // TODO
  CanvasLayoutData handleRescale(
          CanvasItemState item, Offset positionDelta, Offset sizeDelta) =>
      this;
}

class AbsoluteLayoutData extends CanvasLayoutData {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  // if true, the width is scaled by the scale factor when left and right are set
  final bool scaleHorizontal;
  // same as above, but for height
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
    this.scaleHorizontal = false,
    this.scaleVertical = false,
  });

  factory AbsoluteLayoutData.fromJson(Map<String, Object?> json) {
    return AbsoluteLayoutData(
      top: json.getDouble('top'),
      left: json.getDouble('left'),
      right: json.getDouble('right'),
      bottom: json.getDouble('bottom'),
      width: json.getDouble('width'),
      height: json.getDouble('height'),
      shear:
          Offset(json.getDouble('shearX') ?? 0, json.getDouble('shearY') ?? 0),
      scale:
          Offset(json.getDouble('scaleX') ?? 1, json.getDouble('scaleY') ?? 1),
      scaleHorizontal: json.getBool('scaleHorizontal') ?? false,
      scaleVertical: json.getBool('scaleVertical') ?? false,
    );
  }

  @override
  CanvasLayoutData withShear(Offset shear) {
    return copyWith(shear: shear);
  }

  @override
  CanvasLayoutData withScale(Offset scale) {
    return copyWith(scale: scale);
  }

  @override
  bool get doesAffectParentLayout => false;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'absolute',
      'top': top,
      'left': left,
      'right': right,
      'bottom': bottom,
      'width': width,
      'height': height,
      'shearX': shear?.dx,
      'shearY': shear?.dy,
      'scaleHorizontal': scaleHorizontal,
      'scaleVertical': scaleVertical,
      'scaleX': scale?.dx,
      'scaleY': scale?.dy,
    };
  }

  CanvasLayoutData move(CanvasItemState item, Offset delta) {
    var top = this.top;
    var left = this.left;
    var right = this.right;
    var bottom = this.bottom;
    // make sure one axis is available
    if (top == null && bottom == null) {
      top = 0;
    }
    if (left == null && right == null) {
      left = 0;
    }
    return copyWith(
      top: top == null ? null : top + delta.dy,
      left: left == null ? null : left + delta.dx,
      right: right == null ? null : right - delta.dx,
      bottom: bottom == null ? null : bottom - delta.dy,
    );
  }

  @override
  CanvasLayoutData handleResize(
      CanvasItemState item, Offset positionDelta, Offset sizeDelta) {
    double? newTop = top;
    double? newLeft = left;
    double? newRight = right;
    double? newBottom = bottom;
    double? newWidth = width;
    double? newHeight = height;

    if (newTop == null && newBottom == null) {
      newTop = 0;
    } else {
      newHeight ??= 0;
    }
    if (newLeft == null && newRight == null) {
      newLeft = 0;
    } else {
      newWidth ??= 0;
    }

    if (left != null && right != null) {
      // equally distribute the delta to left and right
      double delta = sizeDelta.dx / 2;
      newLeft = left! + delta;
      newRight = right! - delta;
    } else {
      if (left != null) {
        newLeft = left! + positionDelta.dx;
      }
      if (right != null) {
        newRight = right! - positionDelta.dx;
      }
      if (width != null) {
        newWidth = width! + sizeDelta.dx;
      }
    }
    if (top != null && bottom != null) {
      // equally distribute the delta to top and bottom
      double delta = sizeDelta.dy / 2;
      newTop = top! + delta;
      newBottom = bottom! - delta;
    } else {
      if (top != null) {
        newTop = top! + positionDelta.dy;
      }
      if (bottom != null) {
        newBottom = bottom! - positionDelta.dy;
      }
      if (height != null) {
        newHeight = height! + sizeDelta.dy;
      }
    }

    return copyWith(
      top: newTop,
      left: newLeft,
      right: newRight,
      bottom: newBottom,
      width: newWidth,
      height: newHeight,
    );
  }

  @override
  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget) {
    if (targetLayout is FlexLayout) {
      return FixedLayoutData(
        width: SizeConstraint.fixed(item.size.width),
        height: SizeConstraint.fixed(item.size.height),
      );
    }
    return this;
  }

  AbsoluteLayoutData copyWith({
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    double? height,
    Offset? shear,
    Offset? scale,
  }) {
    return AbsoluteLayoutData(
      top: top ?? this.top,
      left: left ?? this.left,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      width: width ?? this.width,
      height: height ?? this.height,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
    );
  }

  @override
  CanvasLayoutData drag(Offset delta) {
    return copyWith(
      top: top == null ? null : top! + delta.dy,
      left: left == null ? null : left! + delta.dx,
      right: right == null ? null : right! - delta.dx,
      bottom: bottom == null ? null : bottom! - delta.dy,
    );
  }

  double computeWidth(double parentWidth) {
    if (width != null) {
      return width!;
    }
    if (left != null && right != null) {
      return parentWidth - left! - right!;
    }
    return 0;
  }

  double computeHeight(double parentHeight) {
    if (height != null) {
      return height!;
    }
    if (top != null && bottom != null) {
      return parentHeight - top! - bottom!;
    }
    return 0;
  }

  @override
  String toString() {
    return 'AbsoluteLayoutData{top: $top, left: $left, right: $right, bottom: $bottom, width: $width, height: $height, shear: $shear, scale: $scale}';
  }
}

class FixedLayoutData extends CanvasLayoutData {
  final SizeConstraint width;
  final SizeConstraint height;

  const FixedLayoutData({
    this.width = const FixedSizeConstraint(0),
    this.height = const FixedSizeConstraint(0),
    super.shear,
    super.scale,
  });

  factory FixedLayoutData.fromJson(Map<String, Object?> json) {
    return FixedLayoutData(
      width: SizeConstraint.fromJson(json.getMap('width') ?? {}),
      height: SizeConstraint.fromJson(json.getMap('height') ?? {}),
      shear:
          Offset(json.getDouble('shearX') ?? 0, json.getDouble('shearY') ?? 0),
      scale:
          Offset(json.getDouble('scaleX') ?? 1, json.getDouble('scaleY') ?? 1),
    );
  }

  @override
  CanvasLayoutData withScale(Offset scale) {
    return copyWith(scale: scale);
  }

  @override
  CanvasLayoutData withShear(Offset shear) {
    return copyWith(shear: shear);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'fixed',
      'width': width.toJson(),
      'height': height.toJson(),
      'shearX': shear?.dx,
      'shearY': shear?.dy,
      'scaleX': scale?.dx,
      'scaleY': scale?.dy,
    };
  }

  @override
  CanvasLayoutData resize(CanvasItemState item, EditorResizeDelta delta) {
    // Offset positionDelta = delta.positionDelta;
    Size sizeDelta = delta.sizeDelta;
    double oldWidth = item.size.width;
    double oldHeight = item.size.height;
    double newWidth = oldWidth + sizeDelta.width;
    double newHeight = oldHeight +
        sizeDelta.height; // TODO: should this be subtracted with positionDelta?
    return copyWith(
      width: FixedSizeConstraint(newWidth),
      height: FixedSizeConstraint(newHeight),
    );
  }

  FixedLayoutData copyWith({
    SizeConstraint? width,
    SizeConstraint? height,
    Offset? shear,
    TextDirection? textDirection,
    Offset? scale,
  }) {
    return FixedLayoutData(
      width: width ?? this.width,
      height: height ?? this.height,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
    );
  }

  @override
  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget) {
    if (targetLayout is FixedLayout) {
      return AbsoluteLayoutData(
        top: dropTarget.dy,
        left: dropTarget.dx,
        width: item.size.width,
        height: item.size.height,
      );
    }
    return this;
  }

  @override
  String toString() {
    return 'FixedLayoutData{width: $width, height: $height, shear: $shear, scale: $scale}';
  }
}

class FlexLayoutData extends CanvasLayoutData {
  final double flex;
  final double min;
  final double max;
  final SizeConstraint cross;

  const FlexLayoutData({
    this.flex = 1,
    this.min = 0,
    this.max = double.infinity,
    this.cross = const IntrinsicSizeConstraint(),
    super.shear,
    super.scale,
  });

  factory FlexLayoutData.fromJson(Map<String, Object?> json) {
    return FlexLayoutData(
      flex: json.getDouble('flex') ?? 1,
      min: json.getDouble('min') ?? 0,
      max: json.getDouble('max') ?? double.infinity,
      cross: SizeConstraint.fromJson(json.getMap('cross') ?? {}),
      shear:
          Offset(json.getDouble('shearX') ?? 0, json.getDouble('shearY') ?? 0),
      scale:
          Offset(json.getDouble('scaleX') ?? 1, json.getDouble('scaleY') ?? 1),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'flex',
      'flex': flex,
      'min': min,
      'max': max,
      'cross': cross.toJson(),
      'shearX': shear?.dx,
      'shearY': shear?.dy,
      'scaleX': scale?.dx,
      'scaleY': scale?.dy,
    };
  }

  @override
  CanvasLayoutData withShear(Offset shear) {
    return copyWith(shear: shear);
  }

  @override
  CanvasLayoutData withScale(Offset scale) {
    return copyWith(scale: scale);
  }

  EditorProperty<double?>? get flexWidth => null;

  @override
  CanvasLayoutData resize(CanvasItemState item, EditorResizeDelta delta) {
    var parent = item.parent;
    if (parent is! CanvasObjectState) {
      return this;
    }
    var parentLayout = parent.item.layout;
    if (parentLayout is! FlexLayout) {
      return this;
    }
    var layoutDirection = parentLayout.direction;
    // Offset positionDelta = delta.positionDelta;
    Size sizeDelta = delta.sizeDelta;
    double oldWidth = item.size.width;
    double oldHeight = item.size.height;
    double newWidth = oldWidth + sizeDelta.width;
    double newHeight = oldHeight +
        sizeDelta.height; // TODO: should this be subtracted with positionDelta?
    // current flex ratio is flex / oldSize
    double newFlex = flex * oldWidth / newWidth;
    return copyWith(
      flex: newFlex,
      cross: layoutDirection == Axis.horizontal
          ? FixedSizeConstraint(newHeight)
          : FixedSizeConstraint(newWidth),
    );
  }

  FlexLayoutData copyWith({
    double? flex,
    double? min,
    double? max,
    SizeConstraint? cross,
    Offset? shear,
    TextDirection? textDirection,
    Offset? scale,
  }) {
    return FlexLayoutData(
      flex: flex ?? this.flex,
      min: min ?? this.min,
      max: max ?? this.max,
      cross: cross ?? this.cross,
      shear: shear ?? this.shear,
      scale: scale ?? this.scale,
    );
  }

  @override
  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget) {
    if (targetLayout is FixedLayout) {
      return AbsoluteLayoutData(
        top: dropTarget.dy,
        left: dropTarget.dx,
        width: item.size.width,
        height: item.size.height,
      );
    }
    return this;
  }

  @override
  String toString() {
    return 'FlexLayoutData{flex: $flex, min: $min, max: $max, cross: $cross, shear: $shear, scale: $scale}';
  }
}
