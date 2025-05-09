import 'package:canvas/canvas.dart';

abstract class CanvasEvent {
  final CanvasEditor editor;

  const CanvasEvent({
    required this.editor,
  });
}

class CanvasLocalSelectionChangedNotification extends CanvasEvent {
  final Selection? selection;

  const CanvasLocalSelectionChangedNotification({
    required super.editor,
    required this.selection,
  });
}

class CanvasItemDraggedNotification extends CanvasEvent {
  final CanvasItemState itemState;

  const CanvasItemDraggedNotification({
    required super.editor,
    required this.itemState,
  });
}

class CanvasItemResizedNotification extends CanvasEvent {
  final CanvasItemState itemState;

  const CanvasItemResizedNotification({
    required super.editor,
    required this.itemState,
  });
}

class CanvasItemsDeletedNotification extends CanvasEvent {
  final List<CanvasItemState> items;

  const CanvasItemsDeletedNotification({
    required super.editor,
    required this.items,
  });
}

class CanvasRulerSnapGuidelineDeletedNotification extends CanvasEvent {
  final CanvasSnapGuideline guideline;

  const CanvasRulerSnapGuidelineDeletedNotification({
    required super.editor,
    required this.guideline,
  });
}
