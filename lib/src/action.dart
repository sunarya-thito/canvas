import 'package:flutter/widgets.dart';

import '../canvas.dart';

abstract class CanvasAction {
  const CanvasAction();
  void undo();
  void redo();
}

class CanvasItemLayoutChangeAction extends CanvasAction {
  final Layout from;
  final Layout to;
  final CanvasItem item;
  const CanvasItemLayoutChangeAction({
    required this.from,
    required this.to,
    required this.item,
  });

  @override
  void undo() {
    item.layout = from;
  }

  @override
  void redo() {
    item.layout = to;
  }
}

class CanvasItemSelectionChangeAction extends CanvasAction {
  final CanvasItem item;
  final bool selected;

  const CanvasItemSelectionChangeAction({
    required this.item,
    required this.selected,
  });

  @override
  void undo() {
    item.selected = !selected;
  }

  @override
  void redo() {
    item.selected = selected;
  }
}

class BulkCanvasAction<T extends CanvasAction> extends CanvasAction {
  final List<T> actions;
  const BulkCanvasAction({
    required this.actions,
  });

  @override
  void undo() {
    for (final action in actions) {
      action.undo();
    }
  }

  @override
  void redo() {
    for (final action in actions) {
      action.redo();
    }
  }
}

class CanvasItemReparentAction extends CanvasAction {
  final CanvasItem item;
  final CanvasItem from;
  final CanvasItem to;
  final List<Layout> fromLayouts;
  final List<Layout> toLayouts;
  const CanvasItemReparentAction({
    required this.item,
    required this.from,
    required this.to,
    required this.fromLayouts,
    required this.toLayouts,
  });

  @override
  void undo() {
    // TODO
  }

  @override
  void redo() {
    // TODO
  }
}

class CanvasItemAddAction extends CanvasAction {
  final CanvasItem parent;
  final CanvasItem item;
  final int index;
  const CanvasItemAddAction({
    required this.parent,
    required this.item,
    required this.index,
  });

  @override
  void undo() {
    parent.removeChildAt(index);
  }

  @override
  void redo() {
    parent.insertChild(index, item);
  }
}

class CanvasItemRemoveAction extends CanvasAction {
  final CanvasItem parent;
  final CanvasItem item;
  final int index;
  const CanvasItemRemoveAction({
    required this.parent,
    required this.item,
    required this.index,
  });

  @override
  void undo() {
    parent.insertChild(index, item);
  }

  @override
  void redo() {
    parent.removeChildAt(index);
  }
}

class CanvasUndoController extends ChangeNotifier {
  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];

  final int bufferSize;
  CanvasUndoController({
    this.bufferSize = 100,
  });

  void add(CanvasAction action) {
    _undoStack.add(action);
    if (_undoStack.length > bufferSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isNotEmpty) {
      final action = _undoStack.removeLast();
      action.undo();
      _redoStack.add(action);
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final action = _redoStack.removeLast();
      action.redo();
      _undoStack.add(action);
      notifyListeners();
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
