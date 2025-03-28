import 'package:flutter/widgets.dart';

class CanvasViewportThemeData {
  final Color backgroundColor;
  final Color isolationColor;
  final Color snappingColor;
  final double snappingStrokeWidth;
  final Decoration canvasDecoration;
  final Decoration selectionDecoration;

  const CanvasViewportThemeData({
    this.backgroundColor = const Color(0xFFB0B0B0),
    this.isolationColor = const Color(0x80FFFFFF),
    this.snappingColor = const Color(0x80198CE8),
    this.snappingStrokeWidth = 1,
    this.canvasDecoration = const BoxDecoration(
      color: Color(0xFFFFFFFF),
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    this.selectionDecoration = const BoxDecoration(
      color: Color(0x806E91E1),
      border: Border(
        top: BorderSide(color: Color(0xFF6E91E1), width: 1),
        left: BorderSide(color: Color(0xFF6E91E1), width: 1),
        right: BorderSide(color: Color(0xFF6E91E1), width: 1),
        bottom: BorderSide(color: Color(0xFF6E91E1), width: 1),
      ),
    ),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasViewportThemeData &&
        other.backgroundColor == backgroundColor &&
        other.isolationColor == isolationColor &&
        other.snappingColor == snappingColor &&
        other.snappingStrokeWidth == snappingStrokeWidth &&
        other.canvasDecoration == canvasDecoration &&
        other.selectionDecoration == selectionDecoration;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        isolationColor,
        snappingColor,
        snappingStrokeWidth,
        canvasDecoration,
        selectionDecoration,
      );
}

class CanvasTransformControlThemeData {
  // final double controlSize;
  // final double controlStrokeWidth;
  // final Color controlStrokeColor;
  // final Color controlFillColor;
  // final Color controlBoundaryColor;
  // final double controlBoundaryWidth;

  // const CanvasTransformControlThemeData({
  //   this.controlSize = 8,
  //   this.controlStrokeWidth = 1,
  //   this.controlStrokeColor = const Color(0xFF6E91E1),
  //   this.controlFillColor = const Color(0xFFFFFFFF),
  //   this.controlBoundaryColor = const Color(0xFF6E91E1),
  //   this.controlBoundaryWidth = 1,
  // });

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;

  //   return other is CanvasTransformControlThemeData &&
  //       other.controlSize == controlSize &&
  //       other.controlStrokeWidth == controlStrokeWidth &&
  //       other.controlStrokeColor == controlStrokeColor &&
  //       other.controlFillColor == controlFillColor &&
  //       other.controlBoundaryColor == controlBoundaryColor &&
  //       other.controlBoundaryWidth == controlBoundaryWidth;
  // }

  // @override
  // int get hashCode => Object.hash(
  //       controlSize,
  //       controlStrokeWidth,
  //       controlStrokeColor,
  //       controlFillColor,
  //       controlBoundaryColor,
  //       controlBoundaryWidth,
  //     );

  final double controlSize;
  // final Decoration controlDecoration;
  final Color controlColor;
  final Color controlBorderColor;
  final double controlBorderWidth;
  // final Decoration controlBoundaryDecoration;
  final Color controlBoundaryBorderColor;
  final double controlBoundaryBorderWidth;

  const CanvasTransformControlThemeData({
    this.controlSize = 10,
    this.controlColor = const Color(0xFFFFFFFF),
    this.controlBorderColor = const Color(0xFF6E91E1),
    this.controlBorderWidth = 1,
    this.controlBoundaryBorderColor = const Color(0xFF6E91E1),
    this.controlBoundaryBorderWidth = 1,
  });
}

class CanvasThemeData {
  final CanvasViewportThemeData viewport;
  final CanvasTransformControlThemeData transformControl;

  const CanvasThemeData({
    this.viewport = const CanvasViewportThemeData(),
    this.transformControl = const CanvasTransformControlThemeData(),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasThemeData &&
        other.viewport == viewport &&
        other.transformControl == transformControl;
  }

  @override
  int get hashCode => Object.hash(viewport, transformControl);
}

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
