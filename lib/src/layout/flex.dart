import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/layout/fixed.dart';
import 'package:flutter/widgets.dart';

enum FlexAlignment {
  start,
  center,
  end;
}

CanvasItemState? _nextFlexChild(CanvasItemState child) {
  CanvasItemState? current = child;
  while (current != null) {
    var next = current.parentData.nextSibling;
    if (next?.item.layoutData is FlexibleLayoutData) {
      return next;
    }
    current = next;
  }
  return null;
}

class FlexLayout extends CanvasLayout {
  final Axis direction;
  final FlexAlignment mainAxisAlignment;
  final FlexAlignment crossAxisAlignment;
  final double spacing;

  @override
  final EdgeInsets padding;

  const FlexLayout({
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = FlexAlignment.start,
    this.crossAxisAlignment = FlexAlignment.start,
    this.spacing = 0.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  bool debugAcceptLayoutData(CanvasItemState item, CanvasLayoutData data) {
    return data is FlexibleLayoutData ||
        data is AbsoluteLayoutData ||
        data is ParentLayoutData;
  }

  @override
  CanvasLayout copyWith({
    ValueGetter<Axis>? direction,
    ValueGetter<FlexAlignment>? mainAxisAlignment,
    ValueGetter<FlexAlignment>? crossAxisAlignment,
    ValueGetter<double>? spacing,
    ValueGetter<EdgeInsets>? padding,
  }) {
    return FlexLayout(
      direction: direction != null ? direction() : this.direction,
      mainAxisAlignment: mainAxisAlignment != null
          ? mainAxisAlignment()
          : this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment != null
          ? crossAxisAlignment()
          : this.crossAxisAlignment,
      spacing: spacing != null ? spacing() : this.spacing,
      padding: padding != null ? padding() : this.padding,
    );
  }

  @override
  CanvasParentData setupParentData(CanvasParentState state,
      CanvasItemState child, CanvasParentData? parentData) {
    if (parentData is CanvasFlexParentData) {
      return parentData;
    } else {
      return CanvasFlexParentData();
    }
  }

  double _getMain(Size size) {
    return direction == Axis.horizontal ? size.width : size.height;
  }

  double _getCross(Size size) {
    return direction == Axis.horizontal ? size.height : size.width;
  }

  double _getMainStart(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.left : padding.top;
  }

  double _getCrossStart(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.top : padding.left;
  }

  double _getCrossEnd(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.bottom : padding.right;
  }

  SizeConstraint? _getMainSizeConstraint(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal ? layoutData.width : layoutData.height;
  }

  SizeConstraint? _getCrossSizeConstraint(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal ? layoutData.height : layoutData.width;
  }

  bool _shouldLayout(CanvasParentState parent, CanvasItemState child) {
    return !(child.targetReparent != null && child.targetReparent != parent);
  }

  Offset _createOffset(double main, double cross) {
    return direction == Axis.horizontal
        ? Offset(main, cross)
        : Offset(cross, main);
  }

  double _getMainPadding(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.horizontal : padding.vertical;
  }

  double _getCrossPadding(EdgeInsets padding) {
    return direction == Axis.horizontal ? padding.vertical : padding.horizontal;
  }

  Size _createSize(double main, double cross) {
    return direction == Axis.horizontal ? Size(main, cross) : Size(cross, main);
  }

  double _getMinMain(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal
        ? layoutData.constraints?.minWidth ?? 0.0
        : layoutData.constraints?.minHeight ?? 0.0;
  }

  double _getMaxMain(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal
        ? layoutData.constraints?.maxWidth ?? double.infinity
        : layoutData.constraints?.maxHeight ?? double.infinity;
  }

  double _getMinCross(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal
        ? layoutData.constraints?.minHeight ?? 0.0
        : layoutData.constraints?.minWidth ?? 0.0;
  }

  double _getMaxCross(FlexibleLayoutData layoutData) {
    return direction == Axis.horizontal
        ? layoutData.constraints?.maxHeight ?? double.infinity
        : layoutData.constraints?.maxWidth ?? double.infinity;
  }

  @override
  void performLayout(CanvasParentState state, Size size) {
    var mainAlignment = mainAxisAlignment;
    var startPadding = _getMainStart(padding);
    var crossStartPadding = _getCrossStart(padding);
    var crossEndPadding = _getCrossEnd(padding);
    var gap = spacing;
    var totalWidth = _getMain(size);
    var crossSize = _getCross(size);

    var offset = _createOffset(startPadding, crossStartPadding);
    var totalMainPadding = _getMainPadding(padding);
    var totalCrossPadding = _getCrossPadding(padding);
    var paddedSize = _createSize(
      totalWidth - totalMainPadding,
      crossSize - totalCrossPadding,
    );

    var hasCrossFlex = false;

    // first phase
    var child = state.firstChild;
    var totalFlex = 0.0;
    var maxCrossFlex = 0.0;
    var totalFixedSize = 0.0;
    var totalAffectedChildren = 0.0;
    while (child != null) {
      if (!_shouldLayout(state, child)) {
        child = child.parentData.nextSibling;
        continue;
      }
      var layoutData = child.item.layoutData;
      var parentData = child.parentData as CanvasFlexParentData;
      if (layoutData is FlexibleLayoutData) {
        var mainSizeConstraint = _getMainSizeConstraint(layoutData);
        var crossSizeConstraint = _getCrossSizeConstraint(layoutData);
        double mainChildSize;
        if (mainSizeConstraint is FixedSizeConstraint) {
          mainChildSize = mainSizeConstraint.size;
        } else if (mainSizeConstraint is UnconstrainedSizeConstraint) {
          totalFlex += 1;
          totalAffectedChildren++;
          child = child.parentData.nextSibling;
          parentData.cachedMainSize = double.infinity;
          continue;
        } else if (mainSizeConstraint is IntrinsicSizeConstraint) {
          mainChildSize = child.computeMinIntrinsicWidth(crossSize);
        } else if (mainSizeConstraint is RelativeSizeConstraint) {
          mainChildSize = mainSizeConstraint.size * paddedSize.width;
        } else if (mainSizeConstraint is FlexSizeConstraint) {
          totalFlex += mainSizeConstraint.flex;
          totalAffectedChildren++;
          child = child.parentData.nextSibling;
          continue;
        } else if (mainSizeConstraint is AspectRatioSizeConstraint) {
          // skip this for now
          mainChildSize = 0.0;
        } else {
          throw UnimplementedError(
              'Unknown size constraint: $mainSizeConstraint');
        }
        parentData.cachedMainSize = mainChildSize;
        double crossChildSize;
        if (crossSizeConstraint is FixedSizeConstraint) {
          crossChildSize = crossSizeConstraint.size;
        } else if (crossSizeConstraint is UnconstrainedSizeConstraint) {
          crossChildSize = _getCross(paddedSize);
        } else if (crossSizeConstraint is IntrinsicSizeConstraint) {
          crossChildSize = child.computeMinIntrinsicHeight(paddedSize.width);
        } else if (crossSizeConstraint is RelativeSizeConstraint) {
          crossChildSize = crossSizeConstraint.size * paddedSize.height;
        } else if (crossSizeConstraint is FlexSizeConstraint) {
          maxCrossFlex = max(maxCrossFlex, crossSizeConstraint.flex);
          hasCrossFlex = true;
          child = _nextFlexChild(child);
          continue;
        } else if (crossSizeConstraint is AspectRatioSizeConstraint) {
          if (mainSizeConstraint is AspectRatioSizeConstraint) {
            throw UnsupportedError(
                'Aspect ratio cannot be used with another aspect ratio');
          }
          var aspectRatio = crossSizeConstraint.aspectRatio;
          crossChildSize = mainChildSize * aspectRatio;
        } else {
          throw UnimplementedError(
              'Unknown size constraint: $crossSizeConstraint');
        }
        if (mainSizeConstraint is AspectRatioSizeConstraint) {
          var aspectRatio = mainSizeConstraint.aspectRatio;
          mainChildSize = crossChildSize * aspectRatio;
          parentData.cachedMainSize = mainChildSize;
        }
        var crossMin = _getMinCross(layoutData);
        var crossMax = _getMaxCross(layoutData);
        crossChildSize = clampIgnoreSign(crossChildSize, crossMin, crossMax);
        parentData.cachedCrossSize = crossChildSize;
        var childSize = _createSize(mainChildSize, crossChildSize);
        child.layout(childSize.constrainIgnoreSign(layoutData.constraints));
        totalFixedSize += mainChildSize;
        totalAffectedChildren++;
      } else if (layoutData is AbsoluteLayoutData) {
        layoutAbsolutePositioning(child, paddedSize, offset, layoutData);
      } else if (layoutData is ParentLayoutData) {
        layoutParentPositioning(child, paddedSize, offset, layoutData);
      } else {
        throw UnimplementedError(
            'Unknown layout data: ${layoutData.runtimeType}');
      }
      child = child.parentData.nextSibling;
    }

    var totalGap =
        totalAffectedChildren > 0 ? gap * (totalAffectedChildren - 1) : 0.0;
    var autoGap = false;
    if (totalGap.isInfinite) {
      gap = 0.0;
      totalGap = 0.0;
      autoGap = true;
    }

    var totalUsedMainSize = totalFixedSize + totalGap;
    var remainingSpace = totalWidth - totalUsedMainSize - totalMainPadding;

    if (hasCrossFlex) {
      var child = state.firstChild;
      while (child != null) {
        if (_shouldLayout(state, child)) {
          var layoutData = child.item.layoutData;
          var parentData = child.parentData as CanvasFlexParentData;
          if (layoutData is FlexibleLayoutData) {
            var crossSizeConstraint = _getCrossSizeConstraint(layoutData);
            if (crossSizeConstraint is FlexSizeConstraint) {
              var flex = crossSizeConstraint.flex;
              var crossChildSize = (flex / maxCrossFlex) * crossSize;
              var minCross = _getMinCross(layoutData);
              var maxCross = _getMaxCross(layoutData);
              crossChildSize =
                  clampIgnoreSign(crossChildSize, minCross, maxCross);
              var mainChildSize = parentData.cachedMainSize;
              var childSize = _createSize(mainChildSize, crossChildSize);
              child.layout(
                  childSize.constrainIgnoreSign(layoutData.constraints));
            }
          }
        }
        child = child.parentData.nextSibling;
      }
    }

    // second phase
    bool needsAnotherPass = true;
    while (needsAnotherPass) {
      needsAnotherPass = false;
      double flexUnit = totalFlex > 0 ? remainingSpace / totalFlex : 0.0;

      child = state.firstChild;
      while (child != null) {
        if (_shouldLayout(state, child)) {
          var layoutData = child.item.layoutData;
          var parentData = child.parentData as CanvasFlexParentData;
          if (layoutData is FlexibleLayoutData) {
            var mainSizeConstraint = _getMainSizeConstraint(layoutData);
            double? flex;
            if (mainSizeConstraint is FlexSizeConstraint) {
              flex = mainSizeConstraint.flex;
            } else if (mainSizeConstraint is UnconstrainedSizeConstraint) {
              flex = 1.0;
            }
            if (flex != null && parentData.mainSize == 0) {
              double proposedSize = flexUnit * flex;
              var minMain = _getMinMain(layoutData);
              var maxMain = _getMaxMain(layoutData);
              if (proposedSize < minMain) {
                parentData.mainSize = minMain;
                remainingSpace -= minMain;
                totalFlex -= flex;
                needsAnotherPass = true;
              } else if (proposedSize > maxMain) {
                parentData.mainSize = maxMain;
                remainingSpace -= maxMain;
                totalFlex -= flex;
                needsAnotherPass = true;
              } else {
                parentData.mainSize = proposedSize;
              }
            }
          }
        }
        child = child.parentData.nextSibling;
      }
    }

    // third phase
    child = state.firstChild;
    while (child != null) {
      if (!_shouldLayout(state, child)) {
        child = child.parentData.nextSibling;
        continue;
      }
      var layoutData = child.item.layoutData;
      var parentData = child.parentData as CanvasFlexParentData;
      if (layoutData is FlexibleLayoutData) {
        var mainSizeConstraint = _getMainSizeConstraint(layoutData);
        if (mainSizeConstraint is UnconstrainedSizeConstraint ||
            mainSizeConstraint is FlexSizeConstraint) {
          var crossChildConstraint = _getCrossSizeConstraint(layoutData);
          double crossChildSize;
          if (crossChildConstraint is FixedSizeConstraint) {
            crossChildSize = crossChildConstraint.size;
          } else if (crossChildConstraint is UnconstrainedSizeConstraint) {
            crossChildSize = _getCross(paddedSize);
          } else if (crossChildConstraint is IntrinsicSizeConstraint) {
            crossChildSize = child.computeMinIntrinsicHeight(paddedSize.width);
          } else if (crossChildConstraint is RelativeSizeConstraint) {
            crossChildSize = crossChildConstraint.size * paddedSize.height;
          } else if (crossChildConstraint is AspectRatioSizeConstraint) {
            var aspectRatio = crossChildConstraint.aspectRatio;
            crossChildSize = parentData.mainSize * aspectRatio;
          } else {
            throw UnimplementedError(
                'Unknown size constraint: $crossChildConstraint');
          }
          var crossMin = _getMinCross(layoutData);
          var crossMax = _getMaxCross(layoutData);
          crossChildSize = clampIgnoreSign(crossChildSize, crossMin, crossMax);
          parentData.cachedCrossSize = crossChildSize;
          var mainChildSize = parentData.mainSize; // already clamped
          var childSize = _createSize(mainChildSize, crossChildSize);
          child.layout(childSize.constrainIgnoreSign(layoutData.constraints));
        }
      }
      child = child.parentData.nextSibling;
    }

    // fourth phase
    var usedMainSize = 0.0;
    child = state.firstChild;
    while (child != null) {
      if (!_shouldLayout(state, child)) {
        child = child.parentData.nextSibling;
        continue;
      }
      var layoutData = child.item.layoutData;
      if (layoutData is FlexibleLayoutData) {
        usedMainSize += _getMain(child.size) + gap;
      }
      child = child.parentData.nextSibling;
    }

    if (autoGap) {
      double remainingSpace = totalWidth - usedMainSize - totalMainPadding;
      if (remainingSpace > 0) {
        gap = remainingSpace / (totalAffectedChildren - 1);
      } else {
        gap = 0.0;
      }
    }

    // final phase
    double mainOffset;
    switch (mainAlignment) {
      case FlexAlignment.start:
        mainOffset = startPadding;
        break;
      case FlexAlignment.center:
        mainOffset = startPadding + (totalWidth - usedMainSize) / 2;
        break;
      case FlexAlignment.end:
        mainOffset = startPadding + (totalWidth - usedMainSize);
        break;
    }

    child = state.firstChild;
    while (child != null) {
      if (!_shouldLayout(state, child)) {
        child = child.parentData.nextSibling;
        continue;
      }
      var layoutData = child.item.layoutData;
      if (layoutData is FlexibleLayoutData) {
        var childSize = child.size;
        double childCrossOffset;
        switch (crossAxisAlignment) {
          case FlexAlignment.start:
            childCrossOffset = crossStartPadding;
            break;
          case FlexAlignment.center:
            childCrossOffset = crossStartPadding +
                (crossSize -
                        (crossStartPadding + crossEndPadding) -
                        _getCross(childSize)) /
                    2;
            break;
          case FlexAlignment.end:
            childCrossOffset =
                crossSize - _getCross(childSize) - crossEndPadding;
            break;
        }
        child.parentData.position = _createOffset(mainOffset, childCrossOffset);
        mainOffset += _getMain(childSize) + gap;
      }
      child = child.parentData.nextSibling;
    }
  }

  double _computeIntrinsicSize(
      CanvasParentState state,
      double size,
      double Function(CanvasItemState item, double size) computeIntrinsicSize,
      double Function() computeCrossIntrinsicSize) {
    var totalSpacing = 0;
    var child = state.firstChild;
    var totalSize = 0.0;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is FlexibleLayoutData) {
        var mainSizeConstraint = _getMainSizeConstraint(layoutData);
        double childSize;
        if (mainSizeConstraint is FixedSizeConstraint) {
          childSize = mainSizeConstraint.size;
        } else if (mainSizeConstraint is UnconstrainedSizeConstraint) {
          childSize = 0;
        } else if (mainSizeConstraint is IntrinsicSizeConstraint) {
          childSize = computeIntrinsicSize(child, size);
        } else if (mainSizeConstraint is RelativeSizeConstraint) {
          childSize = 0;
        } else if (mainSizeConstraint is FlexSizeConstraint) {
          childSize = 0;
        } else if (mainSizeConstraint is AspectRatioSizeConstraint) {
          var aspectRatio = mainSizeConstraint.aspectRatio;
          childSize = size * aspectRatio;
        } else {
          throw UnimplementedError(
              'Unknown size constraint: $mainSizeConstraint');
        }
        var minMain = _getMinMain(layoutData);
        var maxMain = _getMaxMain(layoutData);
        childSize = childSize.clamp(minMain, maxMain);
        totalSize += childSize;
        totalSpacing++;
      }
      child = child.parentData.nextSibling;
    }
    var spacing = this.spacing * (totalSpacing - 1);
    if (spacing.isInfinite) {
      spacing = 0.0;
    }
    return totalSize + spacing + _getMainPadding(padding);
  }

  double _computeCrossIntrinsicSize(
      CanvasParentState state,
      double size,
      double Function(CanvasItemState item, double size) computeIntrinsicSize,
      double Function() computeCrossIntrinsicSize) {
    var totalSize = 0.0;
    var child = state.firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is FlexibleLayoutData) {
        var crossSizeConstraint = _getCrossSizeConstraint(layoutData);
        double childSize;
        if (crossSizeConstraint is FixedSizeConstraint) {
          childSize = crossSizeConstraint.size;
        } else if (crossSizeConstraint is UnconstrainedSizeConstraint) {
          childSize = 0;
        } else if (crossSizeConstraint is IntrinsicSizeConstraint) {
          childSize = computeIntrinsicSize(child, size);
        } else if (crossSizeConstraint is RelativeSizeConstraint) {
          childSize = 0;
        } else if (crossSizeConstraint is FlexSizeConstraint) {
          childSize = 0;
        } else if (crossSizeConstraint is AspectRatioSizeConstraint) {
          var mainSizeConstraint = _getMainSizeConstraint(layoutData);
          if (mainSizeConstraint is AspectRatioSizeConstraint) {
            throw UnsupportedError(
                'Aspect ratio cannot be used with another aspect ratio');
          }
          var aspectRatio = crossSizeConstraint.aspectRatio;
          childSize = computeCrossIntrinsicSize() * aspectRatio;
        } else {
          throw UnimplementedError(
              'Unknown size constraint: $crossSizeConstraint');
        }
        var minCross = _getMinCross(layoutData);
        var maxCross = _getMaxCross(layoutData);
        childSize = childSize.clamp(minCross, maxCross);
        totalSize = max(totalSize, childSize);
      }
      child = child.parentData.nextSibling;
    }
    return totalSize + _getCrossPadding(padding);
  }

  @override
  double computeMaxIntrinsicHeight(CanvasParentState state, double width) {
    return direction == Axis.horizontal
        ? _computeCrossIntrinsicSize(
            state,
            width,
            (item, size) => item.computeMaxIntrinsicHeight(size),
            () => computeMaxIntrinsicWidth(state, double.infinity))
        : _computeIntrinsicSize(
            state,
            width,
            (item, size) => item.computeMaxIntrinsicHeight(size),
            () => computeMaxIntrinsicWidth(state, double.infinity));
  }

  @override
  double computeMaxIntrinsicWidth(CanvasParentState state, double height) {
    return direction == Axis.horizontal
        ? _computeIntrinsicSize(
            state,
            height,
            (item, size) => item.computeMaxIntrinsicWidth(size),
            () => computeMaxIntrinsicHeight(state, double.infinity))
        : _computeCrossIntrinsicSize(
            state,
            height,
            (item, size) => item.computeMaxIntrinsicWidth(size),
            () => computeMaxIntrinsicHeight(state, double.infinity));
  }

  @override
  double computeMinIntrinsicHeight(CanvasParentState state, double width) {
    return direction == Axis.horizontal
        ? _computeCrossIntrinsicSize(
            state,
            width,
            (item, size) => item.computeMinIntrinsicHeight(size),
            () => computeMinIntrinsicWidth(state, double.infinity))
        : _computeIntrinsicSize(
            state,
            width,
            (item, size) => item.computeMinIntrinsicHeight(size),
            () => computeMinIntrinsicWidth(state, double.infinity));
  }

  @override
  double computeMinIntrinsicWidth(CanvasParentState state, double height) {
    return direction == Axis.horizontal
        ? _computeIntrinsicSize(
            state,
            height,
            (item, size) => item.computeMinIntrinsicWidth(size),
            () => computeMinIntrinsicHeight(state, double.infinity))
        : _computeCrossIntrinsicSize(
            state,
            height,
            (item, size) => item.computeMinIntrinsicWidth(size),
            () => computeMinIntrinsicHeight(state, double.infinity));
  }
}

class CanvasFlexParentData extends CanvasParentData {
  double mainSize = 0;
  double cachedMainSize = 0;
  double cachedCrossSize = 0;
}
