import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class EditableFlexLayoutSerializer extends EditableSerializer {
  const EditableFlexLayoutSerializer();
  @override
  void deserialize(CanvasItemState item, DeserializedJson json) {
    if (item is CanvasFrameState) {
      DeserializedJson? layout = json.getMap('layout');
      if (layout != null) {
        String? type = layout.getString('type');
        if (type == 'flex') {
          item.item.layout = FlexLayout(
            direction:
                layout.getEnum('direction', Axis.values) ?? Axis.horizontal,
            mainAxisAlignment:
                layout.getEnum('mainAxisAlignment', FlexAlignment.values) ??
                    FlexAlignment.start,
            crossAxisAlignment:
                layout.getEnum('crossAxisAlignment', FlexAlignment.values) ??
                    FlexAlignment.start,
            padding: EdgeInsets.only(
              top: layout.getDouble('paddingTop') ?? 0,
              left: layout.getDouble('paddingLeft') ?? 0,
              right: layout.getDouble('paddingRight') ?? 0,
              bottom: layout.getDouble('paddingBottom') ?? 0,
            ),
            spacing: layout.getDouble('spacing') ?? double.infinity,
          );
        }
      }
    }
  }

  @override
  void serialize(CanvasItemState item, JsonMap json) {
    if (item is CanvasFrameState) {
      var layout = item.item.layout;
      if (layout is FlexLayout) {
        json['layout'] = JsonMap({
          'type': JsonString('flex'),
          'direction': JsonString(layout.direction.name),
          'mainAxisAlignment': JsonString(layout.mainAxisAlignment.name),
          'crossAxisAlignment': JsonString(layout.crossAxisAlignment.name),
          'paddingTop': JsonDouble(layout.padding.top),
          'paddingLeft': JsonDouble(layout.padding.left),
          'paddingRight': JsonDouble(layout.padding.right),
          'paddingBottom': JsonDouble(layout.padding.bottom),
          'spacing': layout.spacing == double.infinity
              ? null
              : JsonDouble(layout.spacing),
        });
      }
    }
  }
}

class EditableFixedLayoutSerializer extends EditableSerializer {
  const EditableFixedLayoutSerializer();
  @override
  void deserialize(CanvasItemState item, DeserializedJson json) {
    if (item is CanvasFrameState) {
      DeserializedJson? layout = json.getMap('layout');
      if (layout != null) {
        String? type = layout.getString('type');
        if (type == 'fixed') {
          item.item.layout = FixedLayout(
            padding: EdgeInsets.only(
              top: layout.getDouble('paddingTop') ?? 0,
              left: layout.getDouble('paddingLeft') ?? 0,
              right: layout.getDouble('paddingRight') ?? 0,
              bottom: layout.getDouble('paddingBottom') ?? 0,
            ),
          );
        }
      }
    }
  }

  @override
  void serialize(CanvasItemState item, JsonMap json) {
    if (item is CanvasFrameState) {
      var layout = item.item.layout;
      if (layout is FixedLayout) {
        json['layout'] = JsonMap({
          'type': JsonString('fixed'),
          'paddingTop': JsonDouble(layout.padding.top),
          'paddingLeft': JsonDouble(layout.padding.left),
          'paddingRight': JsonDouble(layout.padding.right),
          'paddingBottom': JsonDouble(layout.padding.bottom),
        });
      }
    }
  }
}
