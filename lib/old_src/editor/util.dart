import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';

String optimalDoubleString(double d) {
  // do not use d.toInt() == d method,
  String s = d.toStringAsFixed(2);
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  }
  return s;
}

String shearToString(Offset shear) {
  double x = shear.dx * 180 / pi;
  double y = shear.dy * 180 / pi;
  if (x == -y) {
    // its a rotation
    return '(${optimalDoubleString(x)})';
  }
  return '(${optimalDoubleString(x)},${optimalDoubleString(y)})';
}

double wrapRotation(double angle) {
  const tau = pi * 2;
  return (angle % tau + tau) % tau;
}

extension SizeExtension on Size {
  Offset get asOffset => Offset(width, height);
}

extension OffsetExtension on Offset {
  Size get asSize => Size(dx, dy);
}

extension BorderRadiusExtension on BorderRadius {
  BorderRadiusDirectional get directional {
    return BorderRadiusDirectional.only(
      topStart: topLeft,
      topEnd: topRight,
      bottomStart: bottomLeft,
      bottomEnd: bottomRight,
    );
  }
}

extension JsonExtension on Map<String, Object?> {
  String? getString(String key) {
    var value = this[key];
    return value?.toString();
  }

  int? getInt(String key) {
    var value = this[key];
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? getDouble(String key) {
    var value = this[key];
    if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? getBool(String key) {
    var value = this[key];
    if (value is bool) {
      return value;
    } else if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  Map<String, Object?>? getMap(String key) {
    var value = this[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    return null;
  }
}
