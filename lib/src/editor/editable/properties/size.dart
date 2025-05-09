import 'package:canvas/canvas.dart';

class EditableWidthProvider extends EditablePropertyProvider<SizeConstraint?> {
  const EditableWidthProvider(super.key);

  @override
  SizeConstraint? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.width;
    }
    if (layoutData is FlexibleLayoutData) {
      return layoutData.width;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, SizeConstraint? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData &&
        newValue is ConstrainedSizeConstraint?) {
      editable.item.layoutData = layoutData.copyWith(
        width: () => newValue,
      );
      return true;
    }
    if (layoutData is FlexibleLayoutData && newValue != null) {
      editable.item.layoutData = layoutData.copyWith(
        width: () => newValue,
      );
      return true;
    }
    return false;
  }
}

class EditableHeightProvider extends EditablePropertyProvider<SizeConstraint?> {
  const EditableHeightProvider(super.key);

  @override
  SizeConstraint? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.height;
    }
    if (layoutData is FlexibleLayoutData) {
      return layoutData.height;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, SizeConstraint? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData &&
        newValue is ConstrainedSizeConstraint?) {
      editable.item.layoutData = layoutData.copyWith(
        height: () => newValue,
      );
      return true;
    }
    if (layoutData is FlexibleLayoutData && newValue != null) {
      editable.item.layoutData = layoutData.copyWith(
        height: () => newValue,
      );
      return true;
    }
    return false;
  }
}
