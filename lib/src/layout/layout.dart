import 'package:canvas/canvas.dart';
import 'package:flutter/rendering.dart';

abstract class CanvasLayout {
  const CanvasLayout();
  EdgeInsets get padding;
  CanvasLayout copyWith({ValueGetter<EdgeInsets>? padding});
  CanvasParentData setupParentData(CanvasParentState state,
      CanvasItemState child, CanvasParentData? parentData);
  void performLayout(CanvasParentState state, Size size);
  double computeMinIntrinsicWidth(CanvasParentState state, double height);
  double computeMinIntrinsicHeight(CanvasParentState state, double width);
  double computeMaxIntrinsicWidth(CanvasParentState state, double height);
  double computeMaxIntrinsicHeight(CanvasParentState state, double width);
  bool debugAcceptLayoutData(CanvasItemState item, CanvasLayoutData data);
  void handleDrag(
      CanvasParentState parent, CanvasItemState dragged, Delta delta) {}
}

class CanvasParentData {
  Offset position = Offset.zero;

  CanvasItemState? nextSibling;
  CanvasItemState? previousSibling;
}

void layoutParentPositioning(CanvasItemState child, Size parentSize,
    Offset offset, ParentLayoutData layoutData) {
  child.parentData.position = offset + layoutData.offset;
  child.layout(Size(layoutData.size.width, layoutData.size.height)
      .constrainIgnoreSign(layoutData.constraints));
}
