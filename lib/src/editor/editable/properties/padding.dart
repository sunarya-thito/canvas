import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';

class EditableTopPaddingProvider extends EditablePropertyProvider<double> {
  const EditableTopPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      return editable.item.layout.padding.top;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () => editable.item.layout.padding.copyWith(top: newValue));
      return true;
    }
    return false;
  }
}

class EditableLeftPaddingProvider extends EditablePropertyProvider<double> {
  const EditableLeftPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      return editable.item.layout.padding.left;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () => editable.item.layout.padding.copyWith(left: newValue));
      return true;
    }
    return false;
  }
}

class EditableRightPaddingProvider extends EditablePropertyProvider<double> {
  const EditableRightPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      return editable.item.layout.padding.right;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () =>
              editable.item.layout.padding.copyWith(right: newValue));
      return true;
    }
    return false;
  }
}

class EditableBottomPaddingProvider extends EditablePropertyProvider<double> {
  const EditableBottomPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      return editable.item.layout.padding.bottom;
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () =>
              editable.item.layout.padding.copyWith(bottom: newValue));
      return true;
    }
    return false;
  }
}

class EditableHorizontalPaddingProvider
    extends EditablePropertyProvider<double> {
  const EditableHorizontalPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      final padding = editable.item.layout.padding;
      if (padding.left == padding.right) {
        return padding.left;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () => editable.item.layout.padding.copyWith(
                left: newValue,
                right: newValue,
              ));
      return true;
    }
    return false;
  }
}

class EditableVerticalPaddingProvider extends EditablePropertyProvider<double> {
  const EditableVerticalPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      final padding = editable.item.layout.padding;
      if (padding.top == padding.bottom) {
        return padding.top;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () => editable.item.layout.padding.copyWith(
                top: newValue,
                bottom: newValue,
              ));
      return true;
    }
    return false;
  }
}

class EditableAllPaddingProvider extends EditablePropertyProvider<double> {
  const EditableAllPaddingProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    if (editable is CanvasFrameState) {
      final padding = editable.item.layout.padding;
      if (padding.top == padding.bottom && padding.left == padding.right) {
        return padding.top;
      }
    }
    return null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    if (editable is CanvasFrameState) {
      editable.item.layout = editable.item.layout.copyWith(
          padding: () => editable.item.layout.padding.copyWith(
                top: newValue,
                bottom: newValue,
                left: newValue,
                right: newValue,
              ));
      return true;
    }
    return false;
  }
}
