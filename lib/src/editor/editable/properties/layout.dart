import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';
import 'package:canvas/src/layout/fixed.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/widgets.dart';

enum LayoutType {
  fixed,
  flex,
}

class EditableLayoutProvider extends EditablePropertyProvider<LayoutType> {
  const EditableLayoutProvider(super.key);

  @override
  LayoutType? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        return LayoutType.flex;
      } else {
        return LayoutType.fixed;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, LayoutType newValue) {
    if (editable is CanvasFrameState) {
      if (newValue == LayoutType.flex) {
        editable.item.layout = FlexLayout(
          direction: editable.analyzePossibleFlexDirection(),
          padding: editable.analyzePossiblePadding(),
          spacing: editable.analyzePossibleSpacing(),
          mainAxisAlignment: FlexAlignment.start,
          crossAxisAlignment: FlexAlignment.start,
        );
        for (var child in editable.children) {
          child.item.layoutData = child.item.layoutData
              .handleLayoutChange(child, editable.item.layout);
        }
        return true;
      } else if (newValue == LayoutType.fixed) {
        editable.item.layout = FixedLayout(
          padding: EdgeInsets.zero,
        );
        for (var child in editable.children) {
          child.item.layoutData = child.item.layoutData
              .handleLayoutChange(child, editable.item.layout);
        }
        return true;
      }
    }
    return false;
  }
}

class EditableAbsoluteProvider extends EditablePropertyProvider<bool> {
  const EditableAbsoluteProvider(super.key);

  @override
  bool? handleGetValue(CanvasItemState editable) {
    var parent = editable.parent;
    if (parent is CanvasFrameState) {
      var parentLayout = parent.item.layout;
      if (parentLayout is FlexLayout) {
        var layoutData = editable.item.layoutData;
        return layoutData is AbsoluteLayoutData;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, bool newValue) {
    var parent = editable.parent;
    if (parent is CanvasFrameState) {
      var parentLayout = parent.item.layout;
      if (parentLayout is FlexLayout) {
        if (newValue) {
          editable.item.layoutData = AbsoluteLayoutData(
            top: Position.absolute(editable.parentData.position.dy),
            left: Position.absolute(editable.parentData.position.dx),
            width: SizeConstraint.fixed(editable.size.width),
            height: SizeConstraint.fixed(editable.size.height),
            constraints: editable.item.layoutData.constraints,
          );
        } else {
          editable.item.layoutData = FlexibleLayoutData(
            width: SizeConstraint.fixed(editable.size.width),
            height: SizeConstraint.fixed(editable.size.height),
            constraints: editable.item.layoutData.constraints,
          );
        }
      }
    }
    return false;
  }
}
