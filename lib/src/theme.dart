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
  final double controlSize;
  final Color controlColor;
  final Color controlBorderColor;
  final double controlBorderWidth;
  final Color controlBoundaryBorderColor;
  final double controlBoundaryBorderWidth;
  final Decoration boundsInfoDecoraation;

  const CanvasTransformControlThemeData(
      {this.controlSize = 10,
      this.controlColor = const Color(0xFFFFFFFF),
      this.controlBorderColor = const Color(0xFF6E91E1),
      this.controlBorderWidth = 1,
      this.controlBoundaryBorderColor = const Color(0xFF6E91E1),
      this.controlBoundaryBorderWidth = 1,
      this.boundsInfoDecoraation = const BoxDecoration(
        color: Color(0xFF6E91E1),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      )});
}

class CanvasThemeData {
  final CanvasViewportThemeData viewport;
  final CanvasTransformControlThemeData transformControl;
  final CanvasScrollbarThemeData scrollbar;
  final CanvasRulerThemeData ruler;
  final CanvasSnapThemeData snap;

  const CanvasThemeData({
    this.viewport = const CanvasViewportThemeData(),
    this.transformControl = const CanvasTransformControlThemeData(),
    this.scrollbar = const CanvasScrollbarThemeData(),
    this.ruler = const CanvasRulerThemeData(),
    this.snap = const CanvasSnapThemeData(),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasThemeData &&
        other.viewport == viewport &&
        other.transformControl == transformControl &&
        other.scrollbar == scrollbar &&
        other.ruler == ruler;
  }

  @override
  int get hashCode => Object.hash(viewport, transformControl, scrollbar, ruler);
}

class CanvasScrollbarThemeData {
  final Decoration? trackDecoration;
  final Decoration? thumbDecoration;
  final double thumbThickness;
  final double minThumbLength;
  final EdgeInsetsGeometry trackPadding;

  const CanvasScrollbarThemeData({
    this.trackDecoration,
    this.thumbDecoration = const BoxDecoration(
      color: Color.fromARGB(123, 110, 144, 225),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      border: Border(
        top: BorderSide(color: Color.fromARGB(255, 110, 144, 225), width: 1),
        left: BorderSide(color: Color.fromARGB(255, 110, 144, 225), width: 1),
        right: BorderSide(color: Color.fromARGB(255, 110, 144, 225), width: 1),
        bottom: BorderSide(color: Color.fromARGB(255, 110, 144, 225), width: 1),
      ),
    ),
    this.thumbThickness = 8,
    this.minThumbLength = 150,
    this.trackPadding = const EdgeInsets.all(4),
  });
}

class CanvasRulerThemeData {
  final TextStyle textStyle;
  final double strokeWidth;
  final Color backgroundColor;
  final Color strokeColor;
  final double rulerWidth;
  final double strokeHeight;
  final Color pixelGridColor;
  final Color selectionColor;

  const CanvasRulerThemeData({
    this.textStyle = const TextStyle(
      color: Color.fromARGB(255, 0, 0, 0),
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    this.strokeWidth = 1,
    this.backgroundColor = const Color(0xFFB0B0B0),
    this.strokeColor = const Color.fromARGB(255, 0, 0, 0),
    this.rulerWidth = 25,
    this.strokeHeight = 5,
    this.pixelGridColor = const Color.fromARGB(114, 0, 0, 0),
    this.selectionColor = const Color.fromARGB(123, 110, 144, 225),
  });
}

class CanvasSnapThemeData {
  final double strokeWidth;
  final Color strokeColor;
  final Color selectedStrokeColor;
  final Color hoveredStrokeColor;
  final TextStyle textStyle;

  const CanvasSnapThemeData({
    this.strokeWidth = 1,
    this.strokeColor = const Color.fromARGB(122, 232, 25, 25),
    this.hoveredStrokeColor = const Color.fromARGB(255, 232, 25, 25),
    this.selectedStrokeColor = const Color.fromARGB(255, 110, 144, 225),
    this.textStyle = const TextStyle(
      color: Color.fromARGB(255, 232, 25, 25),
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  });
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
