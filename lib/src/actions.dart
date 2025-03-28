import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

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
