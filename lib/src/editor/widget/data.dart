import 'package:canvas/canvas.dart';
import 'package:data_widget/data_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CanvasEditorWidgetData {
  static CanvasEditorWidgetData find(BuildContext context) {
    return Data.find(context);
  }

  static CanvasEditorWidgetData of(BuildContext context) {
    return Data.of(context);
  }

  final Size viewportSize;
  final PointTransformer globalToLocal;
  final CanvasEditor editor;

  const CanvasEditorWidgetData({
    required this.viewportSize,
    required this.globalToLocal,
    required this.editor,
  });
}
