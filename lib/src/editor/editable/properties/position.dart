import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';

class EditableTopPositionProvider extends EditablePropertyProvider<Position?> {
  const EditableTopPositionProvider(super.key);

  @override
  Position? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.top;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, Position? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      editable.item.layoutData = layoutData.copyWith(
        top: () => newValue,
      );
      return true;
    }
    return false;
  }
}

class EditableLeftPositionProvider extends EditablePropertyProvider<Position?> {
  const EditableLeftPositionProvider(super.key);

  @override
  Position? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.left;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, Position? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      editable.item.layoutData = layoutData.copyWith(
        left: () => newValue,
      );
      return true;
    }
    return false;
  }
}

class EditableRightPositionProvider
    extends EditablePropertyProvider<Position?> {
  const EditableRightPositionProvider(super.key);

  @override
  Position? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.right;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, Position? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      editable.item.layoutData = layoutData.copyWith(
        right: () => newValue,
      );
      return true;
    }
    return false;
  }
}

class EditableBottomPositionProvider
    extends EditablePropertyProvider<Position?> {
  const EditableBottomPositionProvider(super.key);

  @override
  Position? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      return layoutData.bottom;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, Position? newValue) {
    var layoutData = editable.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      editable.item.layoutData = layoutData.copyWith(
        bottom: () => newValue,
      );
      return true;
    }
    return false;
  }
}
