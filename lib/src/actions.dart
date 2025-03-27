import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

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
