import 'dart:ui';

import 'package:canvas/canvas.dart';

class CanvasRoot extends CanvasParent {
  CanvasRoot({
    super.layoutData,
    super.locked,
    super.debugLabel,
    super.children,
  });

  @override
  CanvasParentState createState({CanvasParentState? parent}) {
    return CanvasRootState(item: this, parent: parent);
  }
}

class CanvasRootState extends CanvasParentState {
  CanvasRootState({required super.item, required super.parent});

  @override
  CanvasRoot get item => super.item as CanvasRoot;

  @override
  void forceLayout(Size size) {
    var child = firstChild;
    while (child != null) {
      var layoutData = child.item.layoutData;
      assert(layoutData is ParentLayoutData,
          'CanvasRoot child must have AbsoluteLayoutData');
      layoutParentPositioning(
          child, size, Offset.zero, layoutData as ParentLayoutData);
      child = child.parentData.nextSibling;
    }
    super.forceLayout(size);
  }
}
