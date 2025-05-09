import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

abstract class EditableSerializer {
  static const List<EditableSerializer> serializers = [
    EditableFlexLayoutSerializer(),
    EditableFixedLayoutSerializer(),
    EditableAbsoluteLayoutDataSerializer(),
    EditableFlexibleLayoutDataSerializer(),
  ];
  const EditableSerializer();
  void serialize(CanvasItemState item, JsonMap json);
  void deserialize(CanvasItemState item, DeserializedJson json);
}

typedef JsonMapper<T> = T? Function(Map<String, dynamic> json, String key);

class DeserializedJson {
  final Map<String, dynamic> json;
  DeserializedJson(this.json);

  dynamic operator [](String key) {
    return json[key];
  }

  operator []=(String key, dynamic value) {
    json[key] = value;
  }

  static String? jsonString(Map<String, dynamic> json, String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    return value is String ? value : value.toString();
  }

  static int? jsonInt(Map<String, dynamic> json, String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    return value is int ? value : int.tryParse(value.toString());
  }

  static double? jsonDouble(Map<String, dynamic> json, String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    return value is double ? value : double.tryParse(value.toString());
  }

  static bool? jsonBool(Map<String, dynamic> json, String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    return value is bool ? value : value.toString().toLowerCase() == 'true';
  }

  static JsonMapper<List<T>> jsonList<T>(JsonMapper<T> mapper) {
    return (Map<String, dynamic> json, String key) {
      var value = json[key];
      if (value == null) {
        return null;
      }
      if (value is List) {
        return value.map((e) => mapper(json, e)).toList() as List<T>;
      }
      return null;
    };
  }

  static DeserializedJson? jsonMap(Map<String, dynamic> json, String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return DeserializedJson(value);
    }
    return null;
  }

  static JsonMapper<T> jsonEnum<T extends Enum>(List<T> values) {
    return (Map<String, dynamic> json, String key) {
      var value = json[key];
      if (value == null) {
        return null;
      }
      if (value is T) {
        return value;
      }
      if (value is String) {
        for (var enumValue in values) {
          if (enumValue.name == value) {
            return enumValue;
          }
        }
      }
      return null;
    };
  }

  T? getValue<T>(String key, JsonMapper<T> mapper) {
    return mapper(json, key);
  }

  T? getEnum<T extends Enum>(String key, List<T> values) {
    return jsonEnum(values)(json, key);
  }

  void setEnum<T extends Enum>(String key, T value) {
    json[key] = value.name;
  }

  String? getString(String key) {
    return jsonString(json, key);
  }

  int? getInt(String key) {
    return jsonInt(json, key);
  }

  double? getDouble(String key) {
    return jsonDouble(json, key);
  }

  bool? getBool(String key) {
    return jsonBool(json, key);
  }

  List<T>? getList<T>(String key, JsonMapper<T> mapper) {
    return jsonList(mapper)(json, key);
  }

  List<String>? getStringList(String key) {
    return jsonList(jsonString)(json, key);
  }

  DeserializedJson? getMap(String key) {
    return jsonMap(json, key);
  }

  SizeConstraint? getSizeConstraint(String key) {
    var value = json[key];
    if (value == null) {
      return null;
    }
    DeserializedJson? jsonData = getMap(key);
    String? type = jsonData?.getString('type');
    switch (type) {
      case 'fixed':
        return FixedSizeConstraint(
          jsonData?.getDouble('value') ?? 0,
        );
      case 'flex':
        return FlexSizeConstraint(
          flex: jsonData?.getDouble('flex') ?? 1,
        );
      case 'relative':
        return RelativeSizeConstraint(
          size: jsonData?.getDouble('value') ?? 0,
        );
      case 'intrinsic':
        return IntrinsicSizeConstraint();
      case 'unconstrained':
        return UnconstrainedSizeConstraint();
      case 'aspectRatio':
        return AspectRatioSizeConstraint(
          jsonData?.getDouble('value') ?? 1,
        );
      default:
        return null;
    }
  }

  ConstrainedSizeConstraint getConstrainedSize(String key) {
    var value = json[key];
    if (value == null) {
      return FixedSizeConstraint(0);
    }
    DeserializedJson? jsonData = getMap(key);
    String? type = jsonData?.getString('type');
    switch (type) {
      case 'fixed':
        return FixedSizeConstraint(
          jsonData?.getDouble('value') ?? 0,
        );
      case 'relative':
        return RelativeSizeConstraint(
          size: jsonData?.getDouble('value') ?? 0,
        );
      case 'aspectRatio':
        return AspectRatioSizeConstraint(
          jsonData?.getDouble('value') ?? 1,
        );
      default:
        return FixedSizeConstraint(0);
    }
  }
}

abstract class JsonValue {
  Object? toJson();
}

class JsonString implements JsonValue {
  final String value;

  JsonString(this.value);

  @override
  Object? toJson() {
    return value;
  }
}

class JsonInt implements JsonValue {
  final int value;

  JsonInt(this.value);

  @override
  Object? toJson() {
    return value;
  }
}

class JsonDouble implements JsonValue {
  final double value;

  JsonDouble(this.value);

  @override
  Object? toJson() {
    return value;
  }
}

class JsonBool implements JsonValue {
  final bool value;

  JsonBool(this.value);

  @override
  Object? toJson() {
    return value;
  }
}

class JsonList<T extends JsonValue> implements JsonValue {
  final List<T> value;

  JsonList(this.value);

  T operator [](int index) {
    return value[index];
  }

  operator []=(int index, T value) {
    this.value[index] = value;
  }

  @override
  Object? toJson() {
    return value.map((e) => e.toJson()).toList();
  }
}

class JsonMap implements JsonValue {
  final Map<String, JsonValue?> value;

  JsonMap(this.value);

  JsonValue? operator [](String key) {
    return value[key];
  }

  operator []=(String key, JsonValue? value) {
    this.value[key] = value;
  }

  @override
  Object? toJson() {
    return value.map((key, value) => MapEntry(key, value?.toJson()));
  }
}

JsonMap? serializeConstraints(BoxConstraints? constraints) {
  if (constraints == null) {
    return null;
  }
  return JsonMap({
    'minWidth': JsonDouble(constraints.minWidth),
    'maxWidth': JsonDouble(constraints.maxWidth),
    'minHeight': JsonDouble(constraints.minHeight),
    'maxHeight': JsonDouble(constraints.maxHeight),
  });
}

BoxConstraints? deserializeConstraints(DeserializedJson? json) {
  if (json == null) {
    return null;
  }
  return BoxConstraints(
    minWidth: json.getDouble('minWidth') ?? 0,
    maxWidth: json.getDouble('maxWidth') ?? double.infinity,
    minHeight: json.getDouble('minHeight') ?? 0,
    maxHeight: json.getDouble('maxHeight') ?? double.infinity,
  );
}

JsonMap? serializeOffset(Offset? offset) {
  if (offset == null) {
    return null;
  }
  return JsonMap({
    'dx': JsonDouble(offset.dx),
    'dy': JsonDouble(offset.dy),
  });
}

Offset? deserializeOffset(DeserializedJson? json) {
  if (json == null) {
    return null;
  }
  return Offset(
    json.getDouble('dx') ?? 0,
    json.getDouble('dy') ?? 0,
  );
}

JsonMap? serializePosition(Position? position) {
  if (position == null) {
    return null;
  }
  if (position is AbsolutePosition) {
    return JsonMap({
      'type': JsonString('absolute'),
      'value': JsonDouble(position.value),
    });
  } else if (position is FractionalPosition) {
    return JsonMap({
      'type': JsonString('fractional'),
      'value': JsonDouble(position.value),
    });
  }
  return null;
}

Position? deserializePosition(DeserializedJson? json) {
  if (json == null) {
    return null;
  }
  var type = json.getString('type');
  if (type == 'absolute') {
    return AbsolutePosition(json.getDouble('value') ?? 0);
  } else if (type == 'fractional') {
    return FractionalPosition(json.getDouble('value') ?? 0);
  }
  return null;
}

JsonMap? serializeConstrainedSize(ConstrainedSizeConstraint? size) {
  if (size == null) {
    return null;
  }
  if (size is FixedSizeConstraint) {
    return JsonMap({
      'type': JsonString('fixed'),
      'value': JsonDouble(size.size),
    });
  } else if (size is RelativeSizeConstraint) {
    return JsonMap({
      'type': JsonString('relative'),
      'value': JsonDouble(size.size),
    });
  } else if (size is AspectRatioSizeConstraint) {
    return JsonMap({
      'type': JsonString('aspect_ratio'),
      'value': JsonDouble(size.aspectRatio),
    });
  }
  return null;
}

ConstrainedSizeConstraint? deserializeConstrainedSize(DeserializedJson? json) {
  if (json == null) {
    return null;
  }
  var type = json.getString('type');
  if (type == 'fixed') {
    return FixedSizeConstraint(json.getDouble('value') ?? 0);
  } else if (type == 'relative') {
    return RelativeSizeConstraint(size: json.getDouble('value') ?? 0);
  } else if (type == 'aspect_ratio') {
    return AspectRatioSizeConstraint(json.getDouble('value') ?? 1);
  }
  return null;
}

JsonMap? serializeSizeConstraint(SizeConstraint? size) {
  if (size == null) {
    return null;
  }
  if (size is FixedSizeConstraint) {
    return JsonMap({
      'type': JsonString('fixed'),
      'value': JsonDouble(size.size),
    });
  } else if (size is FlexSizeConstraint) {
    return JsonMap({
      'type': JsonString('flex'),
      'flex': JsonDouble(size.flex),
    });
  } else if (size is RelativeSizeConstraint) {
    return JsonMap({
      'type': JsonString('relative'),
      'value': JsonDouble(size.size),
    });
  } else if (size is IntrinsicSizeConstraint) {
    return JsonMap({
      'type': JsonString('intrinsic'),
    });
  } else if (size is UnconstrainedSizeConstraint) {
    return JsonMap({
      'type': JsonString('unconstrained'),
    });
  } else if (size is AspectRatioSizeConstraint) {
    return JsonMap({
      'type': JsonString('aspect_ratio'),
      'value': JsonDouble(size.aspectRatio),
    });
  }
  return null;
}

SizeConstraint? deserializeSizeConstraint(DeserializedJson? json) {
  if (json == null) {
    return null;
  }
  var type = json.getString('type');
  if (type == 'fixed') {
    return FixedSizeConstraint(json.getDouble('value') ?? 0);
  } else if (type == 'flex') {
    return FlexSizeConstraint(flex: json.getDouble('flex') ?? 1);
  } else if (type == 'relative') {
    return RelativeSizeConstraint(size: json.getDouble('value') ?? 0);
  } else if (type == 'intrinsic') {
    return IntrinsicSizeConstraint();
  } else if (type == 'unconstrained') {
    return UnconstrainedSizeConstraint();
  } else if (type == 'aspect_ratio') {
    return AspectRatioSizeConstraint(json.getDouble('value') ?? 1);
  }
  return null;
}
