import 'package:canvas/canvas.dart';

class SimpleEditableCategory extends EditablePropertyCategory {
  final List<EditablePropertyProvider>? properties;
  const SimpleEditableCategory(super.key, {this.properties});

  @override
  List<EditablePropertyCategoryView>? getViews(CanvasItemState editable) {
    if (properties == null) return null;
    return [EditablePropertyCategoryView(properties: properties)];
  }
}

class EditableFlexLayoutCategory extends EditablePropertyCategory {
  const EditableFlexLayoutCategory(super.key);

  @override
  List<EditablePropertyCategoryView>? getViews(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      var layout = editable.item.layout;
      if (layout is FlexLayout) {
        return [];
      }
    }
    return null;
  }
}
