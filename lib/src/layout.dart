import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

class FixedLayout extends Layout {
  const FixedLayout();
  @override
  void performLayout(CanvasItem item, BoxConstraints constraints) {
    var itemConstraints = item.constraints;
    if (!itemConstraints.constrainedByParent) {
      var newTransform = itemConstraints.constrain(item, constraints);
      item.transform = newTransform;
    }
    for (var child in item.children) {
      child.performLayout(const BoxConstraints());
    }
  }

  @override
  double computeIntrinsicHeight(CanvasItem item) {
    return item.transform.scaledSize.height;
  }

  @override
  double computeIntrinsicWidth(CanvasItem item) {
    return item.transform.scaledSize.width;
  }
}

class FlexLayout extends Layout {
  final FlexAlignment mainAxisAlignment;
  final FlexAlignment crossAxisAlignment;
  final Axis direction;
  final double gap;
  final EdgeInsets padding;

  const FlexLayout({
    this.mainAxisAlignment = FlexAlignment.start,
    this.crossAxisAlignment = FlexAlignment.start,
    this.direction = Axis.horizontal,
    this.gap = 0,
    this.padding = EdgeInsets.zero,
  });

  @override
  double computeIntrinsicHeight(CanvasItem item) {
    // TODO: implement computeIntrinsicHeight
    throw UnimplementedError();
  }

  @override
  double computeIntrinsicWidth(CanvasItem item) {
    // TODO: implement computeIntrinsicWidth
    throw UnimplementedError();
  }

  @override
  void performLayout(CanvasItem item, BoxConstraints constraints) {
    var itemConstraints = item.constraints;
    if (!itemConstraints.constrainedByParent) {
      var newTransform = itemConstraints.constrain(item, constraints);
      item.transform = newTransform;
    }
    var children = item.children;
    if (children.isEmpty) {
      return;
    }
    var gap = this.gap;
    var constrainedSize = constraints.constrain(item.transform.scaledSize);
    List<FlexLayoutPlan> plans = [];
    var maxCrossAxisSize = 0.0;
    var maxCrossFlexSize = 0.0;
    var totalSize = 0.0;
    var totalFlexSize = 0.0;
    for (var child in children) {
      var childConstraints = child.constraints;
      if (childConstraints is FlexibleConstraints) {
        SizeConstraint sizeConstraint =
            childConstraints.getConstraint(direction);
        SizeConstraint crossAxisSizeConstraint =
            childConstraints.getConstraint(crossAxis(direction));
        var plan = sizeConstraint.plan(item, direction);
        plans.add(FlexLayoutPlan(child, plan));
        var crossAxisPlan =
            crossAxisSizeConstraint.plan(item, crossAxis(direction));
        maxCrossAxisSize = max(maxCrossAxisSize, crossAxisPlan.fixedSize);
        maxCrossFlexSize = max(maxCrossFlexSize, crossAxisPlan.flexSize);
        totalSize += plan.fixedSize;
        totalFlexSize += plan.flexSize;
      } else {
        child.performLayout(const BoxConstraints());
      }
    }

    var maxSize = direction == Axis.horizontal
        ? constrainedSize.width
        : constrainedSize.height;
    var maxCrossSize = direction == Axis.vertical
        ? constrainedSize.width
        : constrainedSize.height;
    maxCrossSize -= _paddingSize(padding, crossAxis(direction));
    var flexAllocatedSpace =
        maxSize - totalSize - _paddingSize(padding, direction);
    if (gap.isFinite) {
      flexAllocatedSpace -= gap * (children.length - 1);
    }
    var layoutInfo =
        FlexLayoutInfo(flexAllocatedSpace, item, direction, totalFlexSize);
    var crossAxisInfo = FlexLayoutInfo(
        maxCrossSize, item, crossAxis(direction), maxCrossFlexSize);
    // Second iteration
    // Find out the usedSpace
    var usedSpace = 0.0;
    List<FlexLayoutResult> results = [];
    for (final childPlan in plans) {
      var child = childPlan.item;
      var childConstraints = child.constraints;
      if (childConstraints is FlexibleConstraints) {
        SizeConstraint sizeConstraint =
            childConstraints.getConstraint(direction);
        SizeConstraint crossAxisConstraint =
            childConstraints.getConstraint(crossAxis(direction));
        var size = sizeConstraint.constrain(
            childPlan.plan, item, direction, layoutInfo);
        var crossAxisSize = crossAxisConstraint.constrain(
            childPlan.plan, item, crossAxis(direction), crossAxisInfo);
        usedSpace += size.scaledSize;
        results.add(FlexLayoutResult(child, size, crossAxisSize));
      }
    }
    var remainingSpace = maxSize - usedSpace - _paddingSize(padding, direction);

    // Third iteration
    // Position the children (align them)
    double startOffset =
        direction == Axis.horizontal ? padding.left : padding.top;
    if (gap.isFinite) {
      remainingSpace -= gap * (children.length - 1);
    } else {
      // space between children
      gap = remainingSpace / (children.length - 1);
      remainingSpace = 0;
    }
    switch (mainAxisAlignment) {
      case FlexAlignment.start:
        break;
      case FlexAlignment.end:
        startOffset += remainingSpace;
        break;
      case FlexAlignment.center:
        startOffset += remainingSpace / 2;
        break;
    }
    for (final childResult in results) {
      var child = childResult.item;
      var constraints = child.constraints;
      var size = childResult.usedSpace;
      var crossAxisSize = childResult.crossAxisUsedSpace;
      var crossAxisRemainingSpace = maxCrossSize - crossAxisSize.scaledSize;
      double crossAxisStartOffset =
          direction == Axis.horizontal ? padding.top : padding.left;
      switch (crossAxisAlignment) {
        case FlexAlignment.start:
          break;
        case FlexAlignment.end:
          crossAxisStartOffset += crossAxisRemainingSpace;
          break;
        case FlexAlignment.center:
          crossAxisStartOffset += crossAxisRemainingSpace / 2;
          break;
      }
      var x = direction == Axis.horizontal ? startOffset : crossAxisStartOffset;
      var y = direction == Axis.horizontal ? crossAxisStartOffset : startOffset;
      var width = direction == Axis.horizontal ? size : crossAxisSize;
      var height = direction == Axis.horizontal ? crossAxisSize : size;
      child.transform = LayoutTransform(
        offset: Offset(x, y),
        size: Size(width.size, height.size),
        scale: Offset(width.scale, height.scale),
        rotation: constraints.rotation,
      );
      child.performLayout(BoxConstraints.tightFor(
        width: width.size,
        height: height.size,
      ));
      startOffset += size.scaledSize + gap;
    }
  }
}

class FlexLayoutPlan {
  final CanvasItem item;
  final FlexLayoutPlanInfo plan;

  FlexLayoutPlan(this.item, this.plan);
}

class FlexLayoutPlanInfo {
  final double fixedSize;
  final double flexSize;

  const FlexLayoutPlanInfo({
    this.fixedSize = 0,
    this.flexSize = 0,
  });
}

class FlexLayoutInfo {
  final CanvasItem item;
  final Axis direction;
  final double allocatedSpace;
  final double flexSize;

  FlexLayoutInfo(this.allocatedSpace, this.item, this.direction, this.flexSize);
}

class FlexConstrainResult {
  final double size;
  final double scale;

  FlexConstrainResult({
    this.size = 0,
    this.scale = 1,
  });

  double get scaledSize => size * scale;
}

class FlexLayoutResult {
  final CanvasItem item;
  final FlexConstrainResult usedSpace;
  final FlexConstrainResult crossAxisUsedSpace;

  FlexLayoutResult(this.item, this.usedSpace, this.crossAxisUsedSpace);
}

enum FlexAlignment {
  start,
  end,
  center,
}

double _paddingSize(EdgeInsets padding, Axis axis) {
  return axis == Axis.horizontal ? padding.horizontal : padding.vertical;
}
