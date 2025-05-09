import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/widgets.dart';

class EditableDirectionProvider extends EditablePropertyProvider<Axis> {
  const EditableDirectionProvider(super.key);

  @override
  Axis? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        return layout.direction;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, Axis newValue) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        editable.item.layout = layout.copyWith(
          direction: () => newValue,
        );
        return true;
      }
    }
    return false;
  }
}
