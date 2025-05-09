import 'package:canvas/canvas.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const kPropertyRenderers = <PropertyRenderer>[];
const kDefaultPropertyRenderer = DefaultPropertyRenderer();

PropertyRenderer getPropertyRenderer(Type type) {
  for (var renderer in kPropertyRenderers) {
    if (renderer.rendererType == type) {
      return renderer;
    }
  }
  return kDefaultPropertyRenderer;
}

Widget buildPropertyRenderer(BuildContext context, EditableProperty property) {
  PropertyRenderer renderer = getPropertyRenderer(property.type);
  return renderer.build(context, property);
}

abstract class PropertyRenderer<T> {
  const PropertyRenderer();
  Widget build(BuildContext context, EditableProperty<T> property);
  bool get inline => false;
  Type get rendererType => T;
}

class DefaultPropertyRenderer extends PropertyRenderer<Object?> {
  const DefaultPropertyRenderer();
  @override
  Widget build(BuildContext context, EditableProperty<Object?> property) {
    return Text('${property.value}').muted;
  }
}
