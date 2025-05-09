import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editable/serializer.dart';

class EditableAbsoluteLayoutDataSerializer extends EditableSerializer {
  const EditableAbsoluteLayoutDataSerializer();
  @override
  void deserialize(CanvasItemState item, DeserializedJson json) {
    if (item is CanvasParentState) {
      DeserializedJson? layout = json.getMap('layout');
      if (layout != null) {
        item.item.layoutData = AbsoluteLayoutData(
          top: deserializePosition(layout.getMap('top')),
          left: deserializePosition(layout.getMap('left')),
          right: deserializePosition(layout.getMap('right')),
          bottom: deserializePosition(layout.getMap('bottom')),
          width: deserializeConstrainedSize(layout.getMap('width')),
          height: deserializeConstrainedSize(layout.getMap('height')),
          scaleHorizontal: layout.getBool('scaleHorizontal') ?? false,
          scaleVertical: layout.getBool('scaleVertical') ?? false,
          constraints: deserializeConstraints(layout.getMap('constraints')),
          shear: deserializeOffset(layout.getMap('shear')),
          scale: deserializeOffset(layout.getMap('scale')),
        );
      }
    }
  }

  @override
  void serialize(CanvasItemState item, JsonMap json) {
    var layoutData = item.item.layoutData;
    if (layoutData is AbsoluteLayoutData) {
      json['layout'] = JsonMap({
        'type': JsonString('absolute'),
        'top': serializePosition(layoutData.top),
        'left': serializePosition(layoutData.left),
        'right': serializePosition(layoutData.right),
        'bottom': serializePosition(layoutData.bottom),
        'width': serializeConstrainedSize(layoutData.width),
        'height': serializeConstrainedSize(layoutData.height),
        'scaleHorizontal': JsonBool(layoutData.scaleHorizontal),
        'scaleVertical': JsonBool(layoutData.scaleVertical),
        'constraints': serializeConstraints(layoutData.constraints),
        'shear': serializeOffset(layoutData.shear),
        'scale': serializeOffset(layoutData.scale),
      });
    }
  }
}

class EditableFlexibleLayoutDataSerializer extends EditableSerializer {
  const EditableFlexibleLayoutDataSerializer();
  @override
  void deserialize(CanvasItemState item, DeserializedJson json) {
    if (item is CanvasParentState) {
      DeserializedJson? layout = json.getMap('layout');
      if (layout != null) {
        item.item.layoutData = FlexibleLayoutData(
          width: deserializeSizeConstraint(layout.getMap('width')) ??
              FixedSizeConstraint(0),
          height: deserializeSizeConstraint(layout.getMap('height')) ??
              FixedSizeConstraint(0),
          scale: deserializeOffset(layout.getMap('scale')),
          shear: deserializeOffset(layout.getMap('shear')),
          constraints: deserializeConstraints(layout.getMap('constraints')),
        );
      }
    }
  }

  @override
  void serialize(CanvasItemState item, JsonMap json) {
    var layoutData = item.item.layoutData;
    if (layoutData is FlexibleLayoutData) {
      json['layout'] = JsonMap({
        'type': JsonString('flexible'),
        'width': serializeSizeConstraint(layoutData.width),
        'height': serializeSizeConstraint(layoutData.height),
        'scale': serializeOffset(layoutData.scale),
        'shear': serializeOffset(layoutData.shear),
        'constraints': serializeConstraints(layoutData.constraints),
      });
    }
  }
}
