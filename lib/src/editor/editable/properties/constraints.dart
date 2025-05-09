import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';
import 'package:flutter/widgets.dart';

class EditableMinWidthProvider extends EditablePropertyProvider<double?> {
  const EditableMinWidthProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.constraints?.minWidth;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double? newValue) {
    var layoutData = editable.item.layoutData;
    var constraints = layoutData.constraints;
    constraints ??= BoxConstraints(
      minWidth: newValue ?? 0,
      minHeight: constraints?.minHeight ?? 0,
      maxWidth: constraints?.maxWidth ?? double.infinity,
      maxHeight: constraints?.maxHeight ?? double.infinity,
    );
    editable.item.layoutData = layoutData.copyWith(
      constraints: () => constraints,
    );
    return true;
  }
}

class EditableMinHeightProvider extends EditablePropertyProvider<double?> {
  const EditableMinHeightProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.constraints?.minHeight;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double? newValue) {
    var layoutData = editable.item.layoutData;
    var constraints = layoutData.constraints;
    constraints ??= BoxConstraints(
      minWidth: constraints?.minWidth ?? 0,
      minHeight: newValue ?? 0,
      maxWidth: constraints?.maxWidth ?? double.infinity,
      maxHeight: constraints?.maxHeight ?? double.infinity,
    );
    editable.item.layoutData = layoutData.copyWith(
      constraints: () => constraints,
    );
    return true;
  }
}

class EditableMaxWidthProvider extends EditablePropertyProvider<double?> {
  const EditableMaxWidthProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.constraints?.maxWidth;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double? newValue) {
    var layoutData = editable.item.layoutData;
    var constraints = layoutData.constraints;
    constraints ??= BoxConstraints(
      minWidth: constraints?.minWidth ?? 0,
      minHeight: constraints?.minHeight ?? 0,
      maxWidth: newValue ?? double.infinity,
      maxHeight: constraints?.maxHeight ?? double.infinity,
    );
    editable.item.layoutData = layoutData.copyWith(
      constraints: () => constraints,
    );
    return true;
  }
}

class EditableMaxHeightProvider extends EditablePropertyProvider<double?> {
  const EditableMaxHeightProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.constraints?.maxHeight;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double? newValue) {
    var layoutData = editable.item.layoutData;
    var constraints = layoutData.constraints;
    constraints ??= BoxConstraints(
      minWidth: constraints?.minWidth ?? 0,
      minHeight: constraints?.minHeight ?? 0,
      maxWidth: constraints?.maxWidth ?? double.infinity,
      maxHeight: newValue ?? double.infinity,
    );
    editable.item.layoutData = layoutData.copyWith(
      constraints: () => constraints,
    );
    return true;
  }
}
