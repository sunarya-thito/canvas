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

  CanvasLayoutData resize(CanvasItemState item, EditorResizeDelta delta);

  // dropTarget is local to the target
  CanvasLayoutData transferTo(
      CanvasItemState item, CanvasLayout targetLayout, Offset dropTarget);

  BoxConstraints computeInnerConstraints(
      CanvasItemState item, BoxConstraints constraints) {
    Size smallest = constraints.smallestAllowNegative;
    Size bigest = constraints.biggestAllowNegative;
    if (smallest == bigest) {
      return BoxConstraints.tight(computeInnerSize(item, size: smallest));
    }
    smallest = computeInnerSize(item, size: smallest);
    bigest = computeInnerSize(item, size: bigest);
    return BoxConstraints(
      minWidth: smallest.width,
      minHeight: smallest.height,
      maxWidth: bigest.width,
      maxHeight: bigest.height,
    );
  }

  Size computeInnerSize(CanvasItemState item, {Size? size}) {
    size ??= item.size;
    double width = size.width;
    double height = size.height;
    Matrix4 localMatrix = computeLocalMatrix(item, size: size);
    Offset topLeft = transformOffset(Offset.zero, localMatrix);
    Offset topRight = transformOffset(
      Offset(width, 0),
      localMatrix,
    );
    Offset bottomLeft = transformOffset(
      Offset(0, height),
      localMatrix,
    );
    Offset bottomRight = transformOffset(
      Offset(width, height),
      localMatrix,
    );
    double minX = min(
      min(topLeft.dx, topRight.dx),
      min(bottomLeft.dx, bottomRight.dx),
    );
    double minY = min(
      min(topLeft.dy, topRight.dy),
      min(bottomLeft.dy, bottomRight.dy),
    );
    double maxX = max(
      max(topLeft.dx, topRight.dx),
      max(bottomLeft.dx, bottomRight.dx),
    );
    double maxY = max(
      max(topLeft.dy, topRight.dy),
      max(bottomLeft.dy, bottomRight.dy),
    );
    return Size(
      maxX - minX,
      maxY - minY,
    );
  }

  Matrix4 computeLocalMatrix(CanvasItemState item,
      {Alignment alignment = Alignment.center,
      Matrix4? parentMatrix,
      Size? size}) {
    size ??= item.size;
    Matrix4 transform = (parentMatrix ?? Matrix4.identity());
    Offset origin = alignment.alongSize(size);
    transform.translate(origin.dx, origin.dy);
    if (shear != null) {
      transform *= computeShearMatrix(
        shear!.dx,
        shear!.dy,
      );
    }
    transform.translate(-origin.dx, -origin.dy);
    if (scale != null) {
      transform.scale(scale!.dx, scale!.dy);
    }

    return transform;
  }

  Matrix4 computeTranslatedMatrix(CanvasItemState item,
      {Alignment alignment = Alignment.center, Matrix4? parentMatrix}) {
    Matrix4 transform = Matrix4.identity();
    Offset origin = alignment.alongSize(item.size);
    transform.translate(
        item.parentData.position.dx, item.parentData.position.dy);
    transform.translate(origin.dx, origin.dy);
    if (shear != null) {
      transform *= computeShearMatrix(
        shear!.dx,
        shear!.dy,
      );
    }
    transform.translate(-origin.dx, -origin.dy);
    var size = item.size;
    Offset topLeft = transformOffset(Offset.zero, transform);
    Offset topRight = transformOffset(Offset(size.width, 0), transform);
    Offset bottomLeft = transformOffset(Offset(0, size.height), transform);
    Offset bottomRight =
        transformOffset(Offset(size.width, size.height), transform);
    double minX = min(
      min(topLeft.dx, topRight.dx),
      min(bottomLeft.dx, bottomRight.dx),
    );
    double minY = min(
      min(topLeft.dy, topRight.dy),
      min(bottomLeft.dy, bottomRight.dy),
    );
    double maxX = max(
      max(topLeft.dx, topRight.dx),
      max(bottomLeft.dx, bottomRight.dx),
    );
    double maxY = max(
      max(topLeft.dy, topRight.dy),
      max(bottomLeft.dy, bottomRight.dy),
    );
    double newWidth = maxX - minX;
    double newHeight = maxY - minY;
    double diffWidth = newWidth - size.width;
    double diffHeight = newHeight - size.height;
    transform.translate(-diffWidth / 2, -diffHeight / 2);
    if (parentMatrix != null) {
      transform = parentMatrix * transform;
    }
    return transform;
  }

  CanvasLayoutData drag(Offset delta) => this;

  CanvasLayoutData rotate(double delta) => this;

  CanvasLayoutData rescale(Offset delta,
          {bool symmetric = false,
          bool preserveAspectRatio = false,
          required Alignment alignment}) =>
      this;

  CanvasLayoutData handleResize(Offset positionDelta, Offset sizeDelta) => this;
  CanvasLayoutData handleRescale(Offset positionDelta, Offset sizeDelta) =>
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
    return copyWith(
      top: top == null ? null : top! + delta.dy,
      left: left == null ? null : left! + delta.dx,
      right: right == null ? null : right! - delta.dx,
      bottom: bottom == null ? null : bottom! - delta.dy,
    );
  }

  @override
  CanvasLayoutData resize(CanvasItemState item, EditorResizeDelta delta) {
    Offset positionDelta = delta.positionDelta;
    Size sizeDelta = delta.sizeDelta;
    double? newTop;
    double? newLeft;
    double? newRight;
    double? newBottom;
    double? newWidth;
    double? newHeight;
    if (left != null && right != null) {
      double delta = sizeDelta.width / 2;
      newLeft = left! + delta;
      newRight = right! - delta;
    } else {
      if (left != null) {
        newLeft = left! + positionDelta.dx;
      }
      if (right != null) {
        newRight = right! - positionDelta.dx;
      }
    }
    if (width != null) {
      newWidth = width! + sizeDelta.width;
    }
    if (top != null && bottom != null) {
      // equally distribute the delta to top and bottom
      double delta = sizeDelta.height / 2;
      newTop = top! + delta;
      newBottom = bottom! - delta;
    } else {
      if (top != null) {
        newTop = top! + positionDelta.dy;
      }
      if (bottom != null) {
        newBottom = bottom! - positionDelta.dy;
      }
    }
    if (height != null) {
      newHeight = height! + sizeDelta.height;
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
