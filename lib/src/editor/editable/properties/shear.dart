import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/property.dart';

double rotationFromShear(Offset shear) {
  return (shear.dx - shear.dy) / 2;
}

Offset shearFromRotation(double rotation) {
  return Offset(rotation, -rotation);
}

class EditableRotationProvider extends EditablePropertyProvider<double> {
  const EditableRotationProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.shear != null
        ? rotationFromShear(layoutData.shear!)
        : null;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    editable.item.layoutData = editable.item.layoutData.copyWith(
      shear: () => shearFromRotation(newValue),
    );
    return true;
  }
}

class EditableShearXProvider extends EditablePropertyProvider<double> {
  const EditableShearXProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.shear?.dx ?? 0;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    var layoutData = editable.item.layoutData;
    editable.item.layoutData = layoutData.copyWith(
      shear: () => Offset(newValue, layoutData.shear?.dy ?? 0),
    );
    return true;
  }
}

class EditableShearYProvider extends EditablePropertyProvider<double> {
  const EditableShearYProvider(super.key);

  @override
  double? handleGetValue(CanvasItemState editable) {
    var layoutData = editable.item.layoutData;
    return layoutData.shear?.dy ?? 0;
  }

  @override
  bool handleSetValue(CanvasItemState editable, double newValue) {
    var layoutData = editable.item.layoutData;
    editable.item.layoutData = layoutData.copyWith(
      shear: () => Offset(layoutData.shear?.dx ?? 0, newValue),
    );
    return true;
  }
}
