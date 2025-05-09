import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasDeleteSelectedObjectsIntent extends Intent {
  const CanvasDeleteSelectedObjectsIntent();
}

class CanvasDeleteSelectedObjectsAction
    extends Action<CanvasDeleteSelectedObjectsIntent> {
  final CanvasEditor editor;

  CanvasDeleteSelectedObjectsAction({
    required this.editor,
  });

  @override
  void invoke(covariant CanvasDeleteSelectedObjectsIntent intent) {
    var localSelection = editor.localSelection;
    if (localSelection != null) {
      editor.disposeObjects(localSelection.items);
    }
    var selectedSnapGuideline = editor.selectedSnapGuideline;
    if (selectedSnapGuideline != null) {
      editor.removeRulerSnapAnchor(selectedSnapGuideline);
    }
  }
}

class CanvasSelectAllIntent extends Intent {
  const CanvasSelectAllIntent();
}

class CanvasSelectAllAction extends Action<CanvasSelectAllIntent> {
  final CanvasEditor editor;

  CanvasSelectAllAction({
    required this.editor,
  });

  @override
  void invoke(covariant CanvasSelectAllIntent intent) {
    editor.selectAll();
  }
}

class CanvasDragIntent extends Intent {
  final Offset delta;

  const CanvasDragIntent(this.delta);
}

class CanvasDragAction extends Action<CanvasDragIntent> {
  final CanvasEditor editor;

  CanvasDragAction({
    required this.editor,
  });

  @override
  void invoke(covariant CanvasDragIntent intent) {
    // TODO
  }
}

class CanvasResizeIntent extends Intent {
  final Offset delta;
  final Alignment alignment;

  const CanvasResizeIntent({
    required this.delta,
    required this.alignment,
  });
}

class CanvasResizeAction extends Action<CanvasResizeIntent> {
  final CanvasEditor editor;

  CanvasResizeAction({
    required this.editor,
  });

  @override
  void invoke(covariant CanvasResizeIntent intent) {
    // TODO
  }
}
