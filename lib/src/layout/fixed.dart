import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

void layoutAbsolutePositioning(CanvasItemState child, Size parentSize,
    Offset offset, AbsoluteLayoutData layoutData) {
  double top;
  double left;
  double width;
  double height;
  var dataLeft = layoutData.left;
  var dataRight = layoutData.right;
  var dataTop = layoutData.top;
  var dataBottom = layoutData.bottom;
  var dataWidth = layoutData.width;
  var dataHeight = layoutData.height;
  if (dataWidth != null) {
    width = dataWidth.compute(parentSize.width);
  } else if (dataLeft != null && dataRight != null) {
    if (layoutData.scaleHorizontal) {
      double scaledLeft = parentSize.width * dataLeft.compute(parentSize.width);
      double scaledRight =
          parentSize.width * dataRight.compute(parentSize.width);
      width = parentSize.width - scaledLeft - scaledRight;
    } else {
      width = parentSize.width -
          dataLeft.compute(parentSize.width) -
          dataRight.compute(parentSize.width);
    }
  } else {
    width = child.computeMinIntrinsicWidth(parentSize.height);
  }
  if (dataHeight != null) {
    height = dataHeight.compute(parentSize.height);
  } else if (dataTop != null && dataBottom != null) {
    if (layoutData.scaleVertical) {
      double scaledTop = parentSize.height * dataTop.compute(parentSize.height);
      double scaledBottom =
          parentSize.height * dataBottom.compute(parentSize.height);
      height = parentSize.height - scaledTop - scaledBottom;
    } else {
      height = parentSize.height -
          dataTop.compute(parentSize.height) -
          dataBottom.compute(parentSize.height);
    }
  } else {
    height = child.computeMinIntrinsicHeight(parentSize.width);
  }
  if (dataTop != null) {
    if (layoutData.scaleVertical && dataBottom != null) {
      top = parentSize.height * dataTop.compute(parentSize.height);
    } else {
      top = dataTop.compute(parentSize.height);
    }
  } else if (dataBottom != null) {
    if (layoutData.scaleVertical) {
      top = parentSize.height -
          height -
          parentSize.height * dataBottom.compute(parentSize.height);
    } else {
      top = parentSize.height - height - dataBottom.compute(parentSize.height);
    }
  } else {
    top = 0;
  }
  if (dataLeft != null) {
    if (layoutData.scaleHorizontal && dataRight != null) {
      left = parentSize.width * dataLeft.compute(parentSize.width);
    } else {
      left = dataLeft.compute(parentSize.width);
    }
  } else if (dataRight != null) {
    if (layoutData.scaleHorizontal) {
      left = parentSize.width -
          width -
          parentSize.width * dataRight.compute(parentSize.width);
    } else {
      left = parentSize.width - width - dataRight.compute(parentSize.width);
    }
  } else {
    left = 0;
  }
  if (width.isNegative) {
    left -= width;
  }
  if (height.isNegative) {
    top -= height;
  }
  child.layout(Size(width, height));
  child.parentData.position = Offset(left + offset.dx, top + offset.dy);
}

class FixedLayout extends CanvasLayout {
  @override
  final EdgeInsets padding;

  const FixedLayout({
    this.padding = EdgeInsets.zero,
  });

  double _computeIntrinsicSize(
      CanvasParentState state,
      double size,
      Position? Function(AbsoluteLayoutData layoutData) getStart,
      Position? Function(AbsoluteLayoutData layoutData) getEnd,
      double Function(CanvasItemState item, double size) computeIntrinsicSize) {
    var start = 0.0;
    var end = 0.0;
    var child = state.firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is AbsoluteLayoutData) {
        var childStart = getStart(layoutData) ?? Position.zero;
        if (childStart is! AbsolutePosition) {
          continue;
        }
        var childEnd = getEnd(layoutData);
        double childSize;
        if (childEnd is AbsolutePosition) {
          childSize = childEnd.value - childStart.value;
        } else {
          childSize = computeIntrinsicSize(child, size);
        }
        start = min(start, childStart.value);
        end = max(end, childStart.value + childSize);
      } else {
        end = max(end, computeIntrinsicSize(child, size));
      }
      child = child.parentData.nextSibling;
    }
    return end - start;
  }

  @override
  CanvasParentData setupParentData(CanvasParentState state,
      CanvasItemState child, CanvasParentData? parentData) {
    return parentData ?? CanvasParentData();
  }

  @override
  double computeMaxIntrinsicHeight(CanvasParentState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (item, size) => item.computeMaxIntrinsicHeight(size),
    );
  }

  @override
  double computeMaxIntrinsicWidth(CanvasParentState state, double height) {
    return _computeIntrinsicSize(
      state,
      height,
      (layoutData) => layoutData.left,
      (layoutData) => layoutData.right,
      (item, size) => item.computeMaxIntrinsicWidth(size),
    );
  }

  @override
  double computeMinIntrinsicHeight(CanvasParentState state, double width) {
    return _computeIntrinsicSize(
      state,
      width,
      (layoutData) => layoutData.top,
      (layoutData) => layoutData.bottom,
      (item, size) => item.computeMinIntrinsicHeight(size),
    );
  }

  @override
  double computeMinIntrinsicWidth(CanvasParentState state, double height) {
    return _computeIntrinsicSize(
      state,
      height,
      (layoutData) => layoutData.left,
      (layoutData) => layoutData.right,
      (item, size) => item.computeMinIntrinsicWidth(size),
    );
  }

  @override
  void performLayout(CanvasParentState state, Size size) {
    var paddedSize = Size(
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );
    var paddingOffset = Offset(
      padding.left,
      padding.top,
    );
    var child = state.firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      if (layoutData is AbsoluteLayoutData) {
        layoutAbsolutePositioning(
          child,
          paddedSize,
          paddingOffset,
          layoutData,
        );
      } else {
        child.layout(paddedSize);
        child.parentData.position = paddingOffset;
      }
      child = child.parentData.nextSibling;
    }
  }
}
