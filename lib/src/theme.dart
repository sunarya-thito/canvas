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
}

class CanvasGizmoThemeData {}
