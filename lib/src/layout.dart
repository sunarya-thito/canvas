import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class CanvasParentData {
  Offset position = Offset.zero;
}

abstract class SizeConstraint {
  const factory SizeConstraint.fixed(double size) = FixedSizeConstraint;
  const factory SizeConstraint.intrinsic({
    double min,
    double max,
  }) = IntrinsicSizeConstraint;
  double computeSize(
      CanvasItemState state, double crossSize, Axis axisDirection, bool min);
}

class FixedSizeConstraint implements SizeConstraint {
  final double size;

  const FixedSizeConstraint(this.size);

  @override
  double computeSize(
      CanvasItemState state, double crossSize, Axis axisDirection, bool min) {
    return size;
  }
}

class IntrinsicSizeConstraint implements SizeConstraint {
  final double min;
  final double max;

  const IntrinsicSizeConstraint({this.min = 0, this.max = double.infinity});

  @override
  double computeSize(
      CanvasItemState state, double crossSize, Axis axisDirection, bool min) {
    double size;
    if (!min) {
      if (axisDirection == Axis.horizontal) {
        size = state.computeMaxIntrinsicWidth(crossSize);
        size = size.clamp(this.min, max);
      } else {
        size = state.computeMaxIntrinsicHeight(crossSize);
        size = size.clamp(this.min, max);
      }
      return size;
    }
    if (axisDirection == Axis.horizontal) {
      size = state.computeMinIntrinsicWidth(crossSize);
      size = size.clamp(this.min, max);
    } else {
      size = state.computeMinIntrinsicHeight(crossSize);
      size = size.clamp(this.min, max);
    }
    return size;
  }
}

abstract class CanvasLayoutData {
  final TextDirection? textDirection;
  final double? rotation;
  final Offset? scale;

  const CanvasLayoutData({
    this.textDirection,
    this.rotation,
    this.scale,
  });

  Size computeInnerSize(Size outerSize,
      [Alignment alignment = Alignment.center]) {
    var width = outerSize.width;
    var height = outerSize.height;
    var scale = this.scale ?? const Offset(1, 1);

    // Apply scaling
    var scaledWidth = width / scale.dx;
    var scaledHeight = height / scale.dy;

    return Size(scaledWidth, scaledHeight);
  }

  Matrix4 computeMatrix(Size size, [Alignment alignment = Alignment.center]) {
    Matrix4 matrix = Matrix4.identity();

    var scale = this.scale ?? const Offset(1, 1);
    var rotation = this.rotation ?? 0;

    Offset origin = alignment.alongSize(size);
    matrix.translate(origin.dx, origin.dy);
    matrix.rotateZ(rotation);
    matrix.scale(scale.dx, scale.dy);
    matrix.translate(-origin.dx, -origin.dy);

    Size innerSize = computeInnerSize(size, alignment);

    Offset topLeft = Offset(0, 0);
    Offset topRight = Offset(innerSize.width, 0);
    Offset bottomLeft = Offset(0, innerSize.height);
    Offset bottomRight = Offset(innerSize.width, innerSize.height);

    Offset rotatedTopLeft = transformOffset(topLeft, matrix, origin);
    Offset rotatedTopRight = transformOffset(topRight, matrix, origin);
    Offset rotatedBottomLeft = transformOffset(bottomLeft, matrix, origin);
    Offset rotatedBottomRight = transformOffset(bottomRight, matrix, origin);

    double minX = min(
      min(rotatedTopLeft.dx, rotatedTopRight.dx),
      min(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double maxX = max(
      max(rotatedTopLeft.dx, rotatedTopRight.dx),
      max(rotatedBottomLeft.dx, rotatedBottomRight.dx),
    );
    double minY = min(
      min(rotatedTopLeft.dy, rotatedTopRight.dy),
      min(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );
    double maxY = max(
      max(rotatedTopLeft.dy, rotatedTopRight.dy),
      max(rotatedBottomLeft.dy, rotatedBottomRight.dy),
    );

    double scaleX = size.width / (maxX - minX);
    double scaleY = size.height / (maxY - minY);

    Matrix4 newMatrix = Matrix4.identity();

    newMatrix.translate(origin.dx, origin.dy);
    newMatrix.scale(scaleX, scaleY);
    newMatrix.rotateZ(rotation);
    newMatrix.scale(scale.dx, scale.dy);
    newMatrix.translate(-origin.dx, -origin.dy);

    return newMatrix;
  }
}

class AbsoluteLayoutData extends CanvasLayoutData {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;

  const AbsoluteLayoutData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width,
    this.height,
    super.textDirection,
    super.rotation,
    super.scale,
  });

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
}

class FixedLayoutData extends CanvasLayoutData {
  final SizeConstraint width;
  final SizeConstraint height;

  const FixedLayoutData({
    this.width = const FixedSizeConstraint(0),
    this.height = const FixedSizeConstraint(0),
    super.textDirection,
    super.rotation,
    super.scale,
  });
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
    super.textDirection,
    super.rotation,
    super.scale,
  });
}

abstract class CanvasLayout {
  CanvasParentData setupParentData(
      CanvasItemState state, CanvasParentData? parentData);
  Size performLayout(CanvasItemState state, BoxConstraints constraints,
      TextDirection textDirection);
  double computeMinIntrinsicWidth(CanvasItemState state, double height);
  double computeMaxIntrinsicWidth(CanvasItemState state, double height);
  double computeMinIntrinsicHeight(CanvasItemState state, double width);
  double computeMaxIntrinsicHeight(CanvasItemState state, double width);
}

void layoutAbsolutePositioning(CanvasItemState child, Size parentSize,
    Offset offset, AbsoluteLayoutData layoutData) {
  double top;
  double left;
  double width;
  double height;
  if (layoutData.width != null) {
    width = layoutData.width!;
  } else if (layoutData.left != null && layoutData.right != null) {
    width = parentSize.width - layoutData.left! - layoutData.right!;
  } else {
    width = child.computeMaxIntrinsicWidth(parentSize.height);
  }
  if (layoutData.height != null) {
    height = layoutData.height!;
  } else if (layoutData.top != null && layoutData.bottom != null) {
    height = parentSize.height - layoutData.top! - layoutData.bottom!;
  } else {
    height = child.computeMaxIntrinsicHeight(parentSize.width);
  }
  if (layoutData.top != null) {
    top = layoutData.top!;
  } else if (layoutData.bottom != null) {
    top = parentSize.height - layoutData.bottom! - height;
  } else {
    top = 0;
  }
  if (layoutData.left != null) {
    left = layoutData.left!;
  } else if (layoutData.right != null) {
    left = parentSize.width - layoutData.right! - width;
  } else {
    left = 0;
  }
  child.layout(
    BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: height,
      maxHeight: height,
    ),
    TextDirection.ltr,
  );
  child.parentData.position = offset + Offset(left, top);
}

class FixedLayout implements CanvasLayout {
  const FixedLayout();
  @override
  Size performLayout(CanvasItemState state, BoxConstraints constraints,
      TextDirection textDirection) {
    for (var child in state.children) {
      child.layout(const BoxConstraints(), textDirection);
      var layoutData = child.item.layoutData;
      if (layoutData is AbsoluteLayoutData) {
        layoutAbsolutePositioning(
            child, constraints.biggest, Offset.zero, layoutData);
      }
    }
    return constraints.biggest;
  }

  double _computeIntrinsicSize(
      CanvasItemState state,
      double size,
      double? Function(AbsoluteLayoutData) getStart,
      double? Function(AbsoluteLayoutData) getEnd,
      double Function(CanvasItemState, double) computeIntrinsicSize) {
    var start = 0.0;
    var end = 0.0;
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is AbsoluteLayoutData) {
        var childStart = getStart(layoutData) ?? 0;
        var childEnd = getEnd(layoutData);
        double childSize;
        if (childEnd != null) {
          childSize = childEnd - childStart;
        } else {
          childSize = computeIntrinsicSize(child, size);
        }
        start = min(start, childStart);
        end = max(end, childStart + childSize);
      } else {
        end = max(end, computeIntrinsicSize(child, size));
      }
    }
    return end - start;
  }

  @override
  CanvasParentData setupParentData(
      CanvasItemState state, CanvasParentData? parentData) {
    return parentData ?? CanvasParentData();
  }

  @override
  double computeMinIntrinsicHeight(CanvasItemState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (child, size) => child.computeMinIntrinsicHeight(size),
    );
  }

  @override
  double computeMaxIntrinsicHeight(CanvasItemState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (child, size) => child.computeMaxIntrinsicHeight(size),
    );
  }

  @override
  double computeMaxIntrinsicWidth(CanvasItemState state, double height) {
    return _computeIntrinsicSize(
      state,
      height,
      (layoutData) => layoutData.left,
      (layoutData) => layoutData.right,
      (child, size) => child.computeMaxIntrinsicWidth(size),
    );
  }

  @override
  double computeMinIntrinsicWidth(CanvasItemState state, double height) {
    return _computeIntrinsicSize(
      state,
      height,
      (layoutData) => layoutData.left,
      (layoutData) => layoutData.right,
      (child, size) => child.computeMinIntrinsicWidth(size),
    );
  }
}

enum FlexAlignment {
  start,
  center,
  end,
}

class FlexLayout implements CanvasLayout {
  final Axis direction;
  final FlexAlignment mainAxisAlignment;
  final FlexAlignment crossAxisAlignment;
  final double spacing;
  final EdgeInsetsGeometry padding;

  FlexLayout({
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = FlexAlignment.start,
    this.crossAxisAlignment = FlexAlignment.start,
    this.spacing = 0,
    this.padding = EdgeInsets.zero,
  });

  double _getMain(Size size) {
    return direction == Axis.horizontal ? size.width : size.height;
  }

  double _getCross(Size size) {
    return direction == Axis.horizontal ? size.height : size.width;
  }

  double _getMainStart(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.left : padding.top;
  }

  double _getMainEnd(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.right : padding.bottom;
  }

  double _getCrossStart(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.top : padding.left;
  }

  double _getCrossEnd(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.bottom : padding.right;
  }

  double _getMainPadding(EdgeInsetsGeometry padding) {
    return direction == Axis.horizontal ? padding.horizontal : padding.vertical;
  }

  double _getCrossPadding(EdgeInsetsGeometry padding) {
    return direction == Axis.horizontal ? padding.vertical : padding.horizontal;
  }

  SizeConstraint? _getMainSizeConstraint(FixedLayoutData layoutData) {
    return direction == Axis.horizontal ? layoutData.width : layoutData.height;
  }

  SizeConstraint? _getCrossSizeConstraint(FixedLayoutData layoutData) {
    return direction == Axis.horizontal ? layoutData.height : layoutData.width;
  }

  Axis get crossDirection =>
      direction == Axis.horizontal ? Axis.vertical : Axis.horizontal;

  @override
  Size performLayout(CanvasItemState state, BoxConstraints constraints,
      TextDirection textDirection) {
    var padding = this.padding.resolve(textDirection);
    var mainPadding = _getMainPadding(padding);
    var totalSpacing = 0;
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData || layoutData is FlexLayoutData) {
        totalSpacing++;
      }
    }
    var spacing = this.spacing * (totalSpacing - 1);
    var totalFlex = 0.0;
    var totalSize = 0.0;
    // First iteration
    // 1. Layout the Fixed Children because they have fixed size
    // 2. Compute the total size of the fixed children to get the remaining size for flex children
    // 3. Compute the total flex to compute the sizePerFlex
    // 4. For unknown children, layout them with the same constraints as the parent, make it act like a stack container
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData) {
        var mainSize = _getMainSizeConstraint(layoutData)?.computeSize(
                child, _getMain(constraints.biggest), direction, true) ??
            0;
        var crossSize = _getCrossSizeConstraint(layoutData)?.computeSize(
                child, _getCross(constraints.biggest), crossDirection, true) ??
            0;
        child.layout(_createConstraints(mainSize, crossSize), textDirection);
        totalSize += mainSize;
      } else if (layoutData is FlexLayoutData) {
        totalFlex += layoutData.flex;
      } else if (layoutData is AbsoluteLayoutData) {
        var offsetX = _getMainStart(padding);
        var offsetY = _getCrossStart(padding);
        var offset = Offset(offsetX, offsetY);
        var parentSize = constraints.biggest;
        var paddingMain = _getMainPadding(padding);
        var paddingCross = _getCrossPadding(padding);
        parentSize = Size(
          parentSize.width - paddingMain,
          parentSize.height - paddingCross,
        );
        layoutAbsolutePositioning(child, parentSize, offset, layoutData);
      } else {
        child.layout(constraints, textDirection);
      }
    }
    var remainingSize =
        _getMain(constraints.biggest) - totalSize - spacing - mainPadding;
    var sizePerFlex = totalFlex > 0 ? remainingSize / totalFlex : 0;

    // Second iteration
    // The goal is to eliminate or convert flex children that are too big or too small
    // (constrained by min and max) into fixed size. This is done by clamping the size
    // of the flex children to their min and max size, then layout them as fixed children.
    // Since they're fixed children now, we need to recompute the totalFlex and remainingSize.
    // To avoid recompute, we can just decrease the totalFlex by the flex of the clamped children
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FlexLayoutData) {
        var computedSize = layoutData.flex * sizePerFlex;
        if (computedSize < layoutData.min || computedSize > layoutData.max) {
          var clampedSize = computedSize.clamp(layoutData.min, layoutData.max);
          var crossSize = layoutData.cross.computeSize(
              child, _getCross(constraints.biggest), crossDirection, true);
          child.layout(
            _createConstraints(clampedSize, crossSize),
            textDirection,
          );
          totalFlex -= layoutData.flex;
          remainingSize -= clampedSize;
          totalSize += clampedSize;
        }
      }
    }
    var oldSizePerFlex = sizePerFlex;
    sizePerFlex = totalFlex > 0 ? remainingSize / totalFlex : 0;
    // Third iteration
    // Finally, there is no flex children that are too big or too small here.
    // We can now layout the flex children with the computed sizePerFlex.
    // To identify which children that are previously eliminated/converted to fixed,
    // we can check if the old computed size is too big or too small. If yes,
    // then its the converted children, we can skip them.
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FlexLayoutData) {
        var oldComputedFlex = layoutData.flex * oldSizePerFlex;
        if (oldComputedFlex < layoutData.min ||
            oldComputedFlex > layoutData.max) {
          continue;
        }
        var computedSize = layoutData.flex * sizePerFlex;
        // assert(computedSize >= layoutData.min && computedSize <= layoutData.max,
        //     'Flex child size is not within min and max');
        var crossSize = layoutData.cross.computeSize(
            child, _getCross(constraints.biggest), crossDirection, true);
        child.layout(
          _createConstraints(computedSize, crossSize),
          textDirection,
        );
      }
    }
    double mainContentSize = totalSize + spacing;
    double mainPosition;
    switch (mainAxisAlignment) {
      case FlexAlignment.center:
        mainPosition = _getMain(constraints.biggest) / 2 -
            mainContentSize / 2 +
            _getMainStart(padding);
        break;
      case FlexAlignment.end:
        mainPosition = _getMain(constraints.biggest) -
            mainContentSize -
            _getMainEnd(padding);
        break;
      default:
        mainPosition = _getMainStart(padding);
    }
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData || layoutData is FlexLayoutData) {
        var size = child.size;
        var crossSize = _getCross(size);
        double crossPosition;
        switch (crossAxisAlignment) {
          case FlexAlignment.center:
            crossPosition = _getCross(constraints.biggest) / 2 -
                crossSize / 2 +
                _getCrossStart(padding);
            break;
          case FlexAlignment.end:
            crossPosition = _getCross(constraints.biggest) -
                crossSize -
                _getCrossEnd(padding);
            break;
          default:
            crossPosition = _getCrossStart(padding);
        }
        var position = _createOffset(mainPosition, crossPosition);
        child.parentData.position = position;
        mainPosition += _getMain(size) + this.spacing;
      }
    }
    return constraints.biggest;
  }

  Offset _createOffset(double main, double cross) {
    return direction == Axis.horizontal
        ? Offset(main, cross)
        : Offset(cross, main);
  }

  BoxConstraints _createConstraints(double main, double cross) {
    main = main.clamp(0, double.infinity);
    cross = cross.clamp(0, double.infinity);
    return direction == Axis.horizontal
        ? BoxConstraints(
            minWidth: main,
            maxWidth: main,
            minHeight: cross,
            maxHeight: cross,
          )
        : BoxConstraints(
            minWidth: cross,
            maxWidth: cross,
            minHeight: main,
            maxHeight: main,
          );
  }

  @override
  CanvasParentData setupParentData(
      CanvasItemState state, CanvasParentData? parentData) {
    return parentData ?? CanvasParentData();
  }

  double _computeIntrinsicSize(
    CanvasItemState state,
    double size,
    bool min,
  ) {
    var totalSpacing = 0;
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData || layoutData is FlexLayoutData) {
        totalSpacing++;
      }
    }
    var spacing = this.spacing * (totalSpacing - 1);
    var totalSize = 0.0;
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData) {
        var mainSize = _getMainSizeConstraint(layoutData)
                ?.computeSize(child, size, direction, min) ??
            0;
        totalSize += mainSize;
      } else if (layoutData is FlexLayoutData) {
        totalSize += layoutData.min;
      }
    }
    return totalSize + spacing + _getMainPadding(padding);
  }

  double _computeCrossIntrinsicSize(
      CanvasItemState state, double size, bool min) {
    var totalSize = 0.0;
    for (var child in state.children) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData) {
        var crossSize = _getCrossSizeConstraint(layoutData)
                ?.computeSize(child, size, crossDirection, min) ??
            0;
        totalSize = max(totalSize, crossSize);
      } else if (layoutData is FlexLayoutData) {
        var crossSize =
            layoutData.cross.computeSize(child, size, crossDirection, min);
        totalSize = max(totalSize, crossSize);
      }
    }
    return totalSize + _getCrossPadding(padding);
  }

  @override
  double computeMinIntrinsicHeight(CanvasItemState state, double width) {
    if (direction == Axis.vertical) {
      return _computeIntrinsicSize(
        state,
        width,
        true,
      );
    } else {
      return _computeCrossIntrinsicSize(state, width, true);
    }
  }

  @override
  double computeMaxIntrinsicHeight(CanvasItemState state, double width) {
    if (direction == Axis.vertical) {
      return _computeIntrinsicSize(
        state,
        width,
        false,
      );
    } else {
      return _computeCrossIntrinsicSize(state, width, false);
    }
  }

  @override
  double computeMaxIntrinsicWidth(CanvasItemState state, double height) {
    if (direction == Axis.horizontal) {
      return _computeIntrinsicSize(
        state,
        height,
        false,
      );
    } else {
      return _computeCrossIntrinsicSize(state, height, false);
    }
  }

  @override
  double computeMinIntrinsicWidth(CanvasItemState state, double height) {
    if (direction == Axis.horizontal) {
      return _computeIntrinsicSize(
        state,
        height,
        true,
      );
    } else {
      return _computeCrossIntrinsicSize(state, height, true);
    }
  }
}
