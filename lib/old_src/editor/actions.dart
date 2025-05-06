import 'package:canvas/canvas.dart';
import 'package:canvas/old_src/editor/ruler.dart';
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
      for (var group in localSelection.groups) {
        for (var item in group.selectedItems) {
          editor.removeObject(item);
        }
      }
    }
  }
}

class CanvasCreateRulerSnapAnchorIntent extends Intent {
  final double offset;
  final Axis direction;

  const CanvasCreateRulerSnapAnchorIntent({
    required this.offset,
    required this.direction,
  });
}

class CanvasCreateRulerSnapAnchorAction
    extends Action<CanvasCreateRulerSnapAnchorIntent> {
  final CanvasEditor editor;

  CanvasCreateRulerSnapAnchorAction({
    required this.editor,
  });

  @override
  CanvasSnapGuideline invoke(
      covariant CanvasCreateRulerSnapAnchorIntent intent) {
    return editor.createRulerSnapAnchor(intent.offset, intent.direction);
  }
}

class CanvasRemoveRulerSnapAnchorIntent extends Intent {
  final CanvasSnapGuideline point;

  const CanvasRemoveRulerSnapAnchorIntent({
    required this.point,
  });
}

class CanvasRemoveRulerSnapAnchorAction
    extends Action<CanvasRemoveRulerSnapAnchorIntent> {
  final CanvasEditor editor;
  CanvasRemoveRulerSnapAnchorAction({
    required this.editor,
  });
  @override
  void invoke(covariant CanvasRemoveRulerSnapAnchorIntent intent) {
    editor.removeRulerSnapAnchor(intent.point);
  }
}

class CanvasDeleteItemsIntent extends Intent {
  final List<CanvasItemState> items;

  const CanvasDeleteItemsIntent({
    required this.items,
  });
}

class CanvasDeleteItemsAction extends Action<CanvasDeleteItemsIntent> {
  @override
  void invoke(covariant CanvasDeleteItemsIntent intent) {
    for (var item in intent.items) {
      var parent = item.parent;
      if (parent is CanvasObjectState) {
        parent.item.removeChild(item.item);
      }
    }
  }
}

class CanvasUpdateLayoutDataIntent extends Intent {
  final CanvasItem item;
  final CanvasLayoutData layoutData;

  const CanvasUpdateLayoutDataIntent({
    required this.item,
    required this.layoutData,
  });
}

class CanvasSetLocalSelectionIntent extends Intent {
  final Selection selection;

  const CanvasSetLocalSelectionIntent({
    required this.selection,
  });
}

class CanvasUpdateLayoutDataAction
    extends Action<CanvasUpdateLayoutDataIntent> {
  @override
  void invoke(covariant CanvasUpdateLayoutDataIntent intent) {
    intent.item.layoutData = intent.layoutData;
  }
}

class CanvasUpdateChildrenIntent extends Intent {
  final CanvasObject parent;
  final List<CanvasItem> children;

  const CanvasUpdateChildrenIntent({
    required this.parent,
    required this.children,
  });
}

class CanvasUpdateChildrenAction extends Action<CanvasUpdateChildrenIntent> {
  @override
  bool invoke(covariant CanvasUpdateChildrenIntent intent) {
    intent.parent.children = intent.children;
    return true;
  }
}
