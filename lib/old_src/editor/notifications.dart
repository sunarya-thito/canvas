import 'package:canvas/canvas.dart';
import 'package:canvas/old_src/editor/ruler.dart';
import 'package:flutter/widgets.dart';

class CanvasRulerSnapAnchorCreatedNotification extends Notification {
  final CanvasSnapGuideline point;
  final CanvasEditor editor;

  const CanvasRulerSnapAnchorCreatedNotification({
    required this.point,
    required this.editor,
  });
}

class CanvasRulerSnapAnchorRemovedNotification extends Notification {
  final CanvasSnapGuideline point;
  final CanvasEditor editor;

  const CanvasRulerSnapAnchorRemovedNotification({
    required this.point,
    required this.editor,
  });
}

class CanvasRulerSnapAnchorUpdatedNotification extends Notification {
  final CanvasSnapGuideline point;
  final CanvasEditor editor;

  const CanvasRulerSnapAnchorUpdatedNotification({
    required this.point,
    required this.editor,
  });
}
