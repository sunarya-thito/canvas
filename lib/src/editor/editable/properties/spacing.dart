import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';
import 'package:canvas/src/layout/flex.dart';

class EditableSpacingProvider extends EditablePropertyProvider<double?> {
  const EditableSpacingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        return layout.spacing == double.infinity ? null : layout.spacing;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double? newValue) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        editable.item.layout = layout.copyWith(
          spacing: () => newValue ?? double.infinity,
        );
        return true;
      }
    }
    return false;
  }
}
