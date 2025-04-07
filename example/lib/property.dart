import 'package:canvas/canvas.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const kPropertyRenderers = <PropertyRenderer>[
  StringPropertyRenderer(),
  DoublePropertyRenderer(),
  NullableDoublePropertyRenderer(),
  BooleanPropertyRenderer(),
  EnumPropertyRenderer<LayoutType>(values: LayoutType.values),
  EnumPropertyRenderer<FlexAlignment>(values: FlexAlignment.values),
  EnumPropertyRenderer<Axis>(values: Axis.values),
];
const kDefaultPropertyRenderer = DefaultPropertyRenderer();

PropertyRenderer getPropertyRenderer(Type type) {
  for (var renderer in kPropertyRenderers) {
    if (renderer.rendererType == type) {
      return renderer;
    }
  }
  return kDefaultPropertyRenderer;
}

Widget buildPropertyRenderer(BuildContext context, EditorProperty property) {
  PropertyRenderer renderer = getPropertyRenderer(property.type);
  return renderer.build(context, property);
}

abstract class PropertyRenderer<T> {
  const PropertyRenderer();
  Widget build(BuildContext context, EditorProperty<T> property);
  bool get inline => false;
  Type get rendererType => T;
}

class DefaultPropertyRenderer extends PropertyRenderer<Object?> {
  const DefaultPropertyRenderer();
  @override
  Widget build(BuildContext context, EditorProperty<Object?> property) {
    return Text('${property.value}').muted;
  }
}

class StringPropertyRenderer extends PropertyRenderer<String> {
  const StringPropertyRenderer();
  @override
  Widget build(BuildContext context, EditorProperty<String> property) {
    return TextField(
      initialValue: property.value,
      onChanged: (value) => property.value = value,
    );
  }
}

class DoublePropertyRenderer extends PropertyRenderer<double> {
  const DoublePropertyRenderer();
  @override
  Widget build(BuildContext context, EditorProperty<double> property) {
    return TextField(
      initialValue: optimalDoubleString(property.value),
      onChanged: (value) {
        var parsed = double.tryParse(value);
        property.value = parsed ?? 0;
      },
      submitFormatters: [
        TextInputFormatters.mathExpression(),
      ],
      features: const [
        InputFeature.spinner(),
      ],
    );
  }
}

class NullableDoublePropertyRenderer extends PropertyRenderer<double?> {
  const NullableDoublePropertyRenderer();

  @override
  Widget build(BuildContext context, EditorProperty<double?> property) {
    return TextField(
      initialValue:
          property.value != null ? optimalDoubleString(property.value!) : '',
      onChanged: (value) {
        if (value.isEmpty) {
          property.value = null;
        } else {
          var parsed = double.tryParse(value);
          property.value = parsed;
        }
      },
      submitFormatters: [
        TextInputFormatters.mathExpression(),
      ],
      features: const [
        InputFeature.spinner(),
      ],
    );
  }
}

class BooleanPropertyRenderer extends PropertyRenderer<bool> {
  const BooleanPropertyRenderer();
  @override
  bool get inline => true;

  @override
  Widget build(BuildContext context, EditorProperty<bool> property) {
    return Switch(
      value: property.value,
      onChanged: (value) => property.value = value,
    );
  }
}

class EnumPropertyRenderer<T extends Enum> extends PropertyRenderer<T> {
  final List<T> values;

  const EnumPropertyRenderer({required this.values});

  @override
  Widget build(BuildContext context, EditorProperty<T> property) {
    return ControlledSelect(
      initialValue: property.value,
      onChanged: (value) {
        if (value != null) {
          property.value = value;
        }
      },
      popup: SelectPopup(
        items: SelectItemList(children: [
          for (var value in values)
            SelectItemButton(
              value: value,
              child: Text(value.name),
            ),
        ]),
      ).call,
      itemBuilder: (context, value) {
        return Text(value.name);
      },
    );
  }
}
