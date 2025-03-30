import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/extra.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:cassowary/cassowary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class CanvasParentData {
  Offset position = Offset.zero;
  CanvasItemState? nextSibling;
  CanvasItemState? previousSibling;
}

class CanvasFlexParentData extends CanvasParentData {
  Param mainSize = Param(0);
  double cachedMainSize = 0;
  double cachedCrossSize = 0;
}

abstract class SizeConstraint {
  const factory SizeConstraint.fixed(double size) = FixedSizeConstraint;
  const factory SizeConstraint.intrinsic({
    double min,
    double max,
  }) = IntrinsicSizeConstraint;
  const factory SizeConstraint.unconstrained() = UnconstrainedSizeConstraint;
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

class UnconstrainedSizeConstraint implements SizeConstraint {
  const UnconstrainedSizeConstraint();

  @override
  double computeSize(
      CanvasItemState state, double crossSize, Axis axisDirection, bool min) {
    return double.infinity;
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

abstract class DragResult {
  static const DragResult doNothing = DoNothingDragResult();
  const DragResult();
}

class DoNothingDragResult extends DragResult {
  const DoNothingDragResult();
}

class ReInsertDragResult extends DragResult {
  final CanvasItemState? beforeThis; // if null, then insert at the end
  final Axis direction;

  const ReInsertDragResult(this.beforeThis, this.direction);
}

abstract class CanvasLayout {
  const CanvasLayout();
  CanvasParentData setupParentData(CanvasObjectState state,
      CanvasItemState child, CanvasParentData? parentData);
  Size performLayout(CanvasObjectState state, BoxConstraints constraints,
      TextDirection textDirection);
  double computeMinIntrinsicWidth(CanvasObjectState state, double height);
  double computeMaxIntrinsicWidth(CanvasObjectState state, double height);
  double computeMinIntrinsicHeight(CanvasObjectState state, double width);
  double computeMaxIntrinsicHeight(CanvasObjectState state, double width);

  void visitRelayout(CanvasObjectState item, CanvasItemState child) {
    child.markNeedsLayout();
  }

  DragResult handleDragAttempt(CanvasObjectState item, CanvasItemState dragged,
      CanvasItemState target, Offset localPosition) {
    return DragResult.doNothing;
  }

  Iterable<ExtraTransformationControl> buildControls(CanvasEditorState editor,
      CanvasItemState item, Matrix4 parentTransform, Matrix4 transform) sync* {}
}

void layoutAbsolutePositioning(CanvasItemState child, Size parentSize,
    Offset offset, AbsoluteLayoutData layoutData, TextDirection textDirection) {
  double top;
  double left;
  double width;
  double height;
  if (layoutData.width != null) {
    width = layoutData.width!;
  } else if (layoutData.left != null && layoutData.right != null) {
    if (layoutData.scaleHorizontal) {
      double scaledLeft = parentSize.width * layoutData.left!;
      double scaledRight = parentSize.width * layoutData.right!;
      width = parentSize.width - scaledLeft - scaledRight;
    } else {
      width = parentSize.width - layoutData.left! - layoutData.right!;
    }
  } else {
    width = child.computeMaxIntrinsicWidth(parentSize.height);
  }
  if (layoutData.height != null) {
    height = layoutData.height!;
  } else if (layoutData.top != null && layoutData.bottom != null) {
    if (layoutData.scaleVertical) {
      double scaledTop = parentSize.height * layoutData.top!;
      double scaledBottom = parentSize.height * layoutData.bottom!;
      height = parentSize.height - scaledTop - scaledBottom;
    } else {
      height = parentSize.height - layoutData.top! - layoutData.bottom!;
    }
  } else {
    height = child.computeMaxIntrinsicHeight(parentSize.width);
  }
  if (layoutData.top != null) {
    if (layoutData.scaleVertical && layoutData.bottom != null) {
      top = parentSize.height * layoutData.top!;
    } else {
      top = layoutData.top!;
    }
  } else if (layoutData.bottom != null) {
    top = parentSize.height - layoutData.bottom! - height;
  } else {
    top = 0;
  }
  if (layoutData.left != null) {
    if (layoutData.scaleHorizontal && layoutData.right != null) {
      left = parentSize.width * layoutData.left!;
    } else {
      left = layoutData.left!;
    }
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
      textDirection);
  child.parentData.position = offset + Offset(left, top);
}

class FixedLayout extends CanvasLayout {
  const FixedLayout();
  @override
  Size performLayout(CanvasObjectState state, BoxConstraints constraints,
      TextDirection textDirection) {
    constraints =
        state.item.layoutData.computeInnerConstraints(state, constraints);
    var child = state.firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is AbsoluteLayoutData) {
        layoutAbsolutePositioning(child, constraints.biggestAllowNegative,
            Offset.zero, layoutData, textDirection);
      } else {
        child.layout(constraints, textDirection);
        assert(false, 'FixedLayout can only be used with AbsoluteLayoutData');
        child.parentData.position = Offset.zero;
      }
      child = child.parentData.nextSibling;
    }
    return constraints.biggestAllowNegative;
  }

  @override
  void visitRelayout(CanvasItemState item, CanvasItemState child) {
    item.markNeedsLayout();
  }

  double _computeIntrinsicSize(
      CanvasObjectState state,
      double size,
      double? Function(AbsoluteLayoutData) getStart,
      double? Function(AbsoluteLayoutData) getEnd,
      double Function(CanvasItemState, double) computeIntrinsicSize) {
    var start = 0.0;
    var end = 0.0;
    var child = state.firstChild;
    while (child != null) {
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
      child = child.parentData.nextSibling;
    }
    return end - start;
  }

  @override
  CanvasParentData setupParentData(CanvasObjectState state,
      CanvasItemState child, CanvasParentData? parentData) {
    return parentData ?? CanvasParentData();
  }

  @override
  double computeMinIntrinsicHeight(CanvasObjectState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (child, size) => child.computeMinIntrinsicHeight(size),
    );
  }

  @override
  double computeMaxIntrinsicHeight(CanvasObjectState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (child, size) => child.computeMaxIntrinsicHeight(size),
    );
  }

  @override
  double computeMaxIntrinsicWidth(CanvasObjectState state, double height) {
    return _computeIntrinsicSize(
      state,
      height,
      (layoutData) => layoutData.left,
      (layoutData) => layoutData.right,
      (child, size) => child.computeMaxIntrinsicWidth(size),
    );
  }

  @override
  double computeMinIntrinsicWidth(CanvasObjectState state, double height) {
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
  end;
}

FlexAlignment _resolveFlexAlignment(
    FlexAlignment alignment, TextDirection direction) {
  switch (alignment) {
    case FlexAlignment.start:
      return direction == TextDirection.ltr
          ? FlexAlignment.start
          : FlexAlignment.end;
    case FlexAlignment.center:
      return FlexAlignment.center;
    case FlexAlignment.end:
      return direction == TextDirection.ltr
          ? FlexAlignment.end
          : FlexAlignment.start;
  }
}

class _ConstraintNode extends LinkedNode<_ConstraintNode> {
  Constraint constraint;

  _ConstraintNode(this.constraint);

  @override
  _ConstraintNode? next;
}

bool nonAbsoluteChild(CanvasItemState child) {
  return child.item.layoutData is FlexLayoutData ||
      child.item.layoutData is FixedLayoutData;
}

CanvasItemState? nextNonAbsoluteChild(CanvasItemState child) {
  CanvasItemState? current = child;
  while (current != null) {
    var next = current.parentData.nextSibling;
    if (next != null && nonAbsoluteChild(next)) {
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
  final EdgeInsetsGeometry padding;

  FlexLayout({
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = FlexAlignment.start,
    this.crossAxisAlignment = FlexAlignment.start,
    this.spacing = 0,
    this.padding = EdgeInsets.zero,
  });

  @override
  DragResult handleDragAttempt(CanvasObjectState item, CanvasItemState dragged,
      CanvasItemState target, Offset localPosition) {
    if (dragged == target ||
        target == item ||
        !(nonAbsoluteChild(dragged) && nonAbsoluteChild(target))) {
      return DragResult.doNothing;
    }

    CanvasItemState? beforeThis;
    var size = target.size;
    switch (direction) {
      case Axis.horizontal:
        beforeThis = localPosition.dx < size.width / 2
            ? target
            : nextNonAbsoluteChild(target);
        break;
      case Axis.vertical:
        beforeThis = localPosition.dy < size.height / 2
            ? target
            : nextNonAbsoluteChild(target);
        break;
    }

    return ReInsertDragResult(beforeThis, direction);
  }

  @override
  void visitRelayout(CanvasItemState item, CanvasItemState child) {
    item.markNeedsLayout();
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
  Size performLayout(CanvasObjectState state, BoxConstraints constraints,
      TextDirection textDirection) {
    constraints =
        state.item.layoutData.computeInnerConstraints(state, constraints);
    final watch = Stopwatch();
    watch.start();
    var padding = this.padding.resolve(textDirection);
    var mainAlignment = _resolveFlexAlignment(mainAxisAlignment, textDirection);
    var startPadding = _getMainStart(padding);
    var endPadding = _getMainEnd(padding);
    var crossStartPadding = _getCrossStart(padding);
    var crossEndPadding = _getCrossEnd(padding);
    var gap = spacing;
    var totalWidth = _getMain(constraints.biggestAllowNegative);
    var crossSize = _getCross(constraints.biggestAllowNegative);

    var offset = _createOffset(startPadding, crossStartPadding);
    var totalMainPadding = _getMainPadding(padding);
    var totalCrossPadding = _getCrossPadding(padding);
    var paddedSize = _createSize(
        totalWidth - totalMainPadding, crossSize - totalCrossPadding);

    var solver = Solver();

    // first phase: count flex and remainingSpace, also layout non-flexible child
    var child = _resolveFirstChild(state, textDirection);
    var totalFlex = 0.0;
    var totalFixedSize = 0.0;
    var totalAffectedChildren = 0.0;
    while (child != null) {
      var layoutData = child.item.layoutData;
      var parentData = child.parentData as CanvasFlexParentData;
      if (layoutData is FlexLayoutData) {
        totalFlex += layoutData.flex;
        totalAffectedChildren++;
      } else if (layoutData is FixedLayoutData) {
        var mainChildSize = _getMainSizeConstraint(layoutData)
                ?.computeSize(child, _getCross(paddedSize), direction, false) ??
            0;
        parentData.cachedMainSize = mainChildSize;
        if (mainChildSize.isInfinite) {
          // the child main size asks for infinite space (fill the main axis)
          // we consider this as a flex child (with flex 1)
          totalFlex += 1;
          totalAffectedChildren++;
          child = _resolveNextChild(child, textDirection);
          continue;
        }
        var crossChildSize = _getCrossSizeConstraint(layoutData)?.computeSize(
                child, _getMain(paddedSize), crossDirection, false) ??
            0;
        if (crossChildSize.isInfinite) {
          crossChildSize = _getCross(paddedSize);
        }
        parentData.cachedCrossSize = crossChildSize;
        var childSize = _createConstraints(mainChildSize, crossChildSize);
        child.layout(childSize, textDirection);
        totalFixedSize += _getMain(child.size);
        totalAffectedChildren++;
      } else if (layoutData is AbsoluteLayoutData) {
        layoutAbsolutePositioning(
            child, paddedSize, offset, layoutData, textDirection);
      }
      child = _resolveNextChild(child, textDirection);
    }

    var totalGap =
        totalAffectedChildren > 0 ? gap * (totalAffectedChildren - 1) : 0.0;
    var autoGap = false;
    if (totalGap.isInfinite) {
      gap = 0;
      totalGap = 0;
      autoGap = true;
      // autoGap priority is less important than flex children
      // so if there is a flex children, autoGap will be ignored
      // and the gap set to 0, flex children will take all the remaining space
    }
    var totalUsedMainSize = totalFixedSize + totalGap;
    var remainingSpace = totalWidth - totalUsedMainSize;
    var flexUnit = remainingSpace / totalFlex;

    // second phase: solve constraint
    child = _resolveFirstChild(state, textDirection);
    Expression constraint =
        cm(totalFixedSize + totalGap + totalMainPadding).asExpression();

    _ConstraintNode? first;
    _ConstraintNode? last;

    void appendConstraint(Constraint constraint) {
      var node = _ConstraintNode(constraint);
      if (first == null) {
        first = node;
      } else {
        last!.next = node;
      }
      last = node;
    }

    while (child != null) {
      var layoutData = child.item.layoutData;
      var parentData = child.parentData as CanvasFlexParentData;
      if (layoutData is FlexLayoutData) {
        appendConstraint(
            parentData.mainSize.equals(cm(flexUnit * layoutData.flex))
              ..priority = Priority.weak);
        appendConstraint(parentData.mainSize >= cm(layoutData.min));
        appendConstraint(parentData.mainSize <= cm(layoutData.max));
        constraint += parentData.mainSize;
      } else if (layoutData is FixedLayoutData) {
        var mainChildSize = parentData.cachedMainSize;
        if (mainChildSize.isInfinite) {
          appendConstraint(parentData.mainSize.equals(cm(flexUnit))
            ..priority = Priority.weak);
          constraint += parentData.mainSize;
        }
      }
      child = _resolveNextChild(child, textDirection);
    }
    appendConstraint(
        constraint.equals(cm(totalWidth))..priority = Priority.strong);
    solver.addConstraints(
        LinkedNodeIterable(first).map((e) => e.constraint).toList());
    solver.flushUpdates();
    var usedMainSize = constraint.value;
    remainingSpace = totalWidth - usedMainSize;
    if (remainingSpace > 0 && autoGap) {
      usedMainSize = totalWidth; // left no space, eat all for gap
      gap = remainingSpace / (totalAffectedChildren - 1);
    }

    // third phase, lay out the cross filling children
    child = _resolveFirstChild(state, textDirection);
    while (child != null) {
      var layoutData = child.item.layoutData;
      var parentData = child.parentData as CanvasFlexParentData;
      if (layoutData is FixedLayoutData) {
        var mainChildSize = parentData.cachedMainSize;
        if (mainChildSize.isInfinite) {
          // cross was never cached before, so compute it here
          var crossChildSize = _getCrossSizeConstraint(layoutData)?.computeSize(
                  child, _getMain(paddedSize), crossDirection, false) ??
              0;
          if (crossChildSize.isInfinite) {
            crossChildSize = _getCross(paddedSize);
          }
          parentData.cachedCrossSize = crossChildSize;
          mainChildSize = parentData.mainSize.value;
          var childSize = _createConstraints(mainChildSize, crossChildSize);
          child.layout(childSize, textDirection);
        }
      } else if (layoutData is FlexLayoutData) {
        var mainChildSize = parentData.mainSize.value;
        var crossChildSize = layoutData.cross
            .computeSize(child, _getMain(paddedSize), crossDirection, false);
        if (crossChildSize.isInfinite) {
          crossChildSize = _getCross(paddedSize);
        }
        var childSize = _createConstraints(mainChildSize, crossChildSize);
        child.layout(childSize, textDirection);
      }
      child = _resolveNextChild(child, textDirection);
    }

    // final phase, position the children (only flex and fixed)
    child = _resolveFirstChild(state, textDirection);
    double mainOffset;
    switch (mainAlignment) {
      case FlexAlignment.start:
        mainOffset = startPadding;
        break;
      case FlexAlignment.center:
        mainOffset = startPadding + (totalWidth - usedMainSize) / 2;
        break;
      case FlexAlignment.end:
        mainOffset = totalWidth - usedMainSize - endPadding;
        break;
    }
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData || layoutData is FlexLayoutData) {
        var childSize = child.size;
        double childCrossOffset;
        switch (crossAxisAlignment) {
          case FlexAlignment.start:
            childCrossOffset = crossStartPadding;
            break;
          case FlexAlignment.center:
            childCrossOffset =
                crossStartPadding + (crossSize - childSize.height) / 2;
            break;
          case FlexAlignment.end:
            childCrossOffset = crossSize - childSize.height - crossEndPadding;
            break;
        }
        child.parentData.position = _createOffset(mainOffset, childCrossOffset);
        mainOffset += childSize.width + gap;
      }
      child = _resolveNextChild(child, textDirection);
    }

    watch.stop();

    return constraints.biggestAllowNegative;
  }

  CanvasItemState? _resolveFirstChild(
      CanvasObjectState parent, TextDirection direction) {
    switch (direction) {
      case TextDirection.ltr:
        return parent.firstChild;
      case TextDirection.rtl:
        return parent.lastChild;
    }
  }

  CanvasItemState? _resolveNextChild(
      CanvasItemState previousChild, TextDirection direction) {
    switch (direction) {
      case TextDirection.ltr:
        return previousChild.parentData.nextSibling;
      case TextDirection.rtl:
        return previousChild.parentData.previousSibling;
    }
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

  Size _createSize(double main, double cross) {
    return direction == Axis.horizontal ? Size(main, cross) : Size(cross, main);
  }

  @override
  CanvasParentData setupParentData(CanvasObjectState state,
      CanvasItemState child, CanvasParentData? parentData) {
    if (parentData is! CanvasFlexParentData) {
      return CanvasFlexParentData();
    }
    return parentData;
  }

  double _computeIntrinsicSize(
    CanvasObjectState state,
    double size,
    bool min,
  ) {
    var totalSpacing = 0;
    var child = state.firstChild;
    var totalSize = 0.0;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData) {
        var mainSize = _getMainSizeConstraint(layoutData)
                ?.computeSize(child, size, direction, min) ??
            0;
        if (!mainSize.isInfinite) {
          totalSize += mainSize;
        }
        totalSpacing++;
      } else if (layoutData is FlexLayoutData) {
        totalSize += layoutData.min;
        totalSpacing++;
      }
      child = child.parentData.nextSibling;
    }
    var spacing = this.spacing * (totalSpacing - 1);
    if (spacing.isInfinite) {
      spacing = 0;
    }
    return totalSize + spacing + _getMainPadding(padding);
  }

  double _computeCrossIntrinsicSize(
      CanvasObjectState state, double size, bool min) {
    var totalSize = 0.0;
    var child = state.firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is FixedLayoutData) {
        var crossSize = _getCrossSizeConstraint(layoutData)
                ?.computeSize(child, size, crossDirection, min) ??
            0;
        if (crossSize.isInfinite) {
          child = child.parentData.nextSibling;
          continue;
        }
        totalSize = max(totalSize, crossSize);
      } else if (layoutData is FlexLayoutData) {
        var crossSize =
            layoutData.cross.computeSize(child, size, crossDirection, min);
        if (crossSize.isInfinite) {
          child = child.parentData.nextSibling;
          continue;
        }
        totalSize = max(totalSize, crossSize);
      }
      child = child.parentData.nextSibling;
    }
    return totalSize + _getCrossPadding(padding);
  }

  @override
  double computeMinIntrinsicHeight(CanvasObjectState state, double width) {
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
  double computeMaxIntrinsicHeight(CanvasObjectState state, double width) {
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
  double computeMaxIntrinsicWidth(CanvasObjectState state, double height) {
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
  double computeMinIntrinsicWidth(CanvasObjectState state, double height) {
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
