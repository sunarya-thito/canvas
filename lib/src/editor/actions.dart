import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

class CanvasCreateRulerSnappingPointIntent extends Intent {
  final double offset;
  final Axis direction;
  final CanvasEditorHandler editor;

  const CanvasCreateRulerSnappingPointIntent({
    required this.offset,
    required this.direction,
    required this.editor,
  });
}

class CanvasCreateRulerSnappingPointAction
    extends Action<CanvasCreateRulerSnappingPointIntent> {
  @override
  CanvasRulerSnappingPoint invoke(
      covariant CanvasCreateRulerSnappingPointIntent intent) {
    return intent.editor
        .createRulerSnappingPoint(intent.offset, intent.direction);
  }
}

class CanvasRemoveRulerSnappingPointIntent extends Intent {
  final CanvasRulerSnappingPoint point;
  final CanvasEditorHandler editor;

  const CanvasRemoveRulerSnappingPointIntent({
    required this.point,
    required this.editor,
  });
}

class CanvasRemoveRulerSnappingPointAction
    extends Action<CanvasRemoveRulerSnappingPointIntent> {
  @override
  void invoke(covariant CanvasRemoveRulerSnappingPointIntent intent) {
    intent.editor.removeRulerSnappingPoint(intent.point);
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
