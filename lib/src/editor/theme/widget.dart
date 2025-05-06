import 'package:flutter/widgets.dart';

import 'theme.dart';

class CanvasTheme extends InheritedTheme {
  final CanvasThemeData data;

  const CanvasTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static CanvasThemeData of(BuildContext context) {
    final CanvasTheme? canvasTheme =
        context.dependOnInheritedWidgetOfExactType<CanvasTheme>();
    return canvasTheme?.data ?? const CanvasThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CanvasTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(CanvasTheme oldWidget) {
    return data != oldWidget.data;
  }
}
