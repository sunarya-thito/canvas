import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:flutter/widgets.dart';

class CanvasRulerSnappingPointCreatedNotification extends Notification {
  final CanvasRulerSnappingPoint point;
  final CanvasEditorHandler editor;

  const CanvasRulerSnappingPointCreatedNotification({
    required this.point,
    required this.editor,
  });
}

class CanvasRulerSnappingPointRemovedNotification extends Notification {
  final CanvasRulerSnappingPoint point;
  final CanvasEditorHandler editor;

  const CanvasRulerSnappingPointRemovedNotification({
    required this.point,
    required this.editor,
  });
}

class CanvasRulerSnappingPointUpdatedNotification extends Notification {
  final CanvasRulerSnappingPoint point;
  final CanvasEditorHandler editor;

  const CanvasRulerSnappingPointUpdatedNotification({
    required this.point,
    required this.editor,
  });
}
