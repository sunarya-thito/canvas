import 'package:canvas/canvas.dart';
import 'package:canvas/src/item/frame.dart';
import 'package:flutter/widgets.dart';

class EditableVerticalAlignmentProvider
    extends EditablePropertyProvider<FlexAlignment> {
  const EditableVerticalAlignmentProvider(super.key);

  @override
  FlexAlignment handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        var direction = layout.direction;
        if (direction == Axis.vertical) {
          return layout.mainAxisAlignment;
        } else if (direction == Axis.horizontal) {
          return layout.crossAxisAlignment;
        }
      }
    }
    return FlexAlignment.start;
  }

  @override
  bool handleSetValue(CanvasItemState editable, FlexAlignment newValue) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        var direction = layout.direction;
        if (direction == Axis.vertical) {
          editable.item.layout = layout.copyWith(
            mainAxisAlignment: () => newValue,
          );
        } else if (direction == Axis.horizontal) {
          editable.item.layout = layout.copyWith(
            crossAxisAlignment: () => newValue,
          );
        }
        return true;
      }
    }
    return false;
  }
}

class EditableHorizontalAlignmentProvider
    extends EditablePropertyProvider<FlexAlignment> {
  const EditableHorizontalAlignmentProvider(super.key);

  @override
  FlexAlignment handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        var direction = layout.direction;
        if (direction == Axis.horizontal) {
          return layout.mainAxisAlignment;
        } else if (direction == Axis.vertical) {
          return layout.crossAxisAlignment;
        }
      }
    }
    return FlexAlignment.start;
  }

  @override
  bool handleSetValue(CanvasItemState editable, FlexAlignment newValue) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        var direction = layout.direction;
        if (direction == Axis.horizontal) {
          editable.item.layout = layout.copyWith(
            mainAxisAlignment: () => newValue,
          );
        } else if (direction == Axis.vertical) {
          editable.item.layout = layout.copyWith(
            crossAxisAlignment: () => newValue,
          );
        }
        return true;
      }
    }
    return false;
  }
}
