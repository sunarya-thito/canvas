import 'dart:collection';

import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasItem {
  final String? debugLabel;

  CanvasItem({this.debugLabel});

  final List<CanvasItemState> _attachedStates = [];
  CanvasLayoutData get layoutData;
  set layoutData(CanvasLayoutData value);

  void attach(CanvasItemState state) {
    _attachedStates.add(state);
  }

  void detach(CanvasItemState state) {
    _attachedStates.remove(state);
  }

  CanvasItemState createState({
    CanvasItemState? parent,
  });

  List<CanvasItemState> get activeStates => List.unmodifiable(_attachedStates);

  // Editor specific properties
  Offset? _editorOffset;
  Offset? get editorOffset => _editorOffset;
  set editorOffset(Offset? value) {
    if (value != _editorOffset) {
      _editorOffset = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }
  //
}

CanvasParentData _migrateParentData(
    CanvasParentData? oldParentData, CanvasParentData newParentData) {
  if (oldParentData == null) return newParentData;
  newParentData.nextSibling = oldParentData.nextSibling;
  newParentData.previousSibling = oldParentData.previousSibling;
  newParentData.position = oldParentData.position;
  return newParentData;
}

class CanvasObject extends CanvasItem {
  CanvasLayout _layout;
  CanvasLayoutData _layoutData;
  List<CanvasItem> _children = [];
  @override
  List<CanvasObjectState> get _attachedStates =>
      super._attachedStates.cast<CanvasObjectState>();

  CanvasObject({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
    super.debugLabel,
  })  : _layout = layout,
        _layoutData = layoutData,
        _children = List.of(children);
  @override
  CanvasItemState createState({CanvasItemState? parent}) {
    return CanvasObjectState(
      parent: parent,
      item: this,
    );
  }

  @override
  void attach(CanvasItemState state) {
    super.attach(state);
    var parent = state.parent;
    if (parent is CanvasObjectState) {
      // ask parent to setup parent data for this new attached state
      var layout = parent.item.layout;
      var oldParentData = state._parentData;
      var newParentData = layout.setupParentData(parent, state, oldParentData);
      state._parentData = _migrateParentData(oldParentData, newParentData);
    } else {
      state._parentData = CanvasParentData();
    }
    (state as CanvasObjectState).buildChildren(_children);
  }

  CanvasLayout get layout => _layout;
  set layout(CanvasLayout value) {
    if (value != _layout) {
      _layout = value;
      for (var state in _attachedStates) {
        for (var child in state.children) {
          var oldParentData = child._parentData;
          var newParentData =
              value.setupParentData(state, child, oldParentData);
          child._parentData = _migrateParentData(oldParentData, newParentData);
        }
        state.requestRelayout();
      }
    }
  }

  @override
  CanvasLayoutData get layoutData => _layoutData;
  @override
  set layoutData(CanvasLayoutData value) {
    if (value != _layoutData) {
      _layoutData = value;
      for (var state in _attachedStates) {
        state.requestRelayout();
      }
    }
  }

  List<CanvasItem> get children => List.unmodifiable(_children);

  set children(List<CanvasItem> value) {
    if (!listEquals(value, _children)) {
      _children = value;
      for (var state in _attachedStates) {
        state.buildChildren(value);
        state.requestRelayout();
      }
    }
  }

  @override
  String toString() {
    return 'CanvasObject{debugLabel: $debugLabel}';
  }
}

class _CachedLayout {
  final Size size;
  final BoxConstraints constraints;
  final TextDirection textDirection;

  _CachedLayout({
    required this.size,
    required this.constraints,
    required this.textDirection,
  });
}

abstract class CanvasItemState implements Listenable {
  CanvasItemState? parent;
  CanvasItem get item;
  CanvasParentData? _parentData;
  _CachedLayout? _layoutResult;

  CanvasItemState({this.parent});

  CanvasParentData get parentData {
    var parentData = _parentData;
    assert(parentData != null, 'Parent data not set');
    return parentData!;
  }

  Widget? render(BuildContext context) => null;

  bool isDescendantOf(CanvasItemState state) {
    var parent = this.parent;
    while (parent != null) {
      if (parent == state) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  Size get size {
    assert(_layoutResult != null, 'CanvasItem $this has not been laid out');
    return _layoutResult!.size;
  }

  bool hasLayoutPerformedFor(
      BoxConstraints constraints, TextDirection textDirection) {
    return _layoutResult != null &&
        _layoutResult!.constraints == constraints &&
        _layoutResult!.textDirection == textDirection;
  }

  bool get hasSize => _layoutResult != null;

  void requestRelayout();
  void requestChildRelayout(CanvasItemState child);

  void markNeedsLayout();

  void forceRelayout() {
    var cached = _layoutResult;
    assert(cached != null, 'CanvasItem $this has not been laid out');
    forceLayout(cached!.constraints, cached.textDirection);
  }

  void dispose() {}

  void layout(BoxConstraints constraints, TextDirection textDirection) {
    if (!hasLayoutPerformedFor(constraints, textDirection)) {
      var size = forceLayout(constraints, textDirection);
      _layoutResult = _CachedLayout(
        size: size,
        constraints: constraints,
        textDirection: textDirection,
      );
    }
  }

  Size forceLayout(BoxConstraints constraints, TextDirection textDirection);

  double computeMinIntrinsicWidth(double height);
  double computeMaxIntrinsicWidth(double height);
  double computeMinIntrinsicHeight(double width);
  double computeMaxIntrinsicHeight(double width);
}

class CanvasItemChildrenIterator implements Iterator<CanvasItemState> {
  CanvasObjectState parent;
  CanvasItemState? _current;
  bool _first = true;

  CanvasItemChildrenIterator(this.parent) : _current = parent.firstChild;

  @override
  CanvasItemState get current {
    assert(_current != null, 'No current item');
    return _current!;
  }

  @override
  bool moveNext() {
    if (_first) {
      _first = false;
      return _current != null;
    }
    if (_current == null) return false;
    _current = _current!.parentData.nextSibling;
    return _current != null;
  }
}

class CanvasItemChildrenIterable extends Iterable<CanvasItemState> {
  final CanvasObjectState parent;

  CanvasItemChildrenIterable(this.parent);

  @override
  Iterator<CanvasItemState> get iterator => CanvasItemChildrenIterator(parent);
}

class CanvasItemNode extends LinkedNode<CanvasItemNode> {
  final CanvasItemState item;
  @override
  CanvasItemNode? next;

  CanvasItemNode(this.item, this.next);
}

class CanvasObjectState extends CanvasItemState with ChangeNotifier {
  @override
  final CanvasObject item;

  CanvasObjectState({
    super.parent,
    required this.item,
  });

  set children(Iterable<CanvasItemState> children) {
    item.children = children.map((e) => e.item).toList();
  }

  Iterable<CanvasItemState> get children => CanvasItemChildrenIterable(this);

  CanvasItemState? _firstChild;
  CanvasItemState? _lastChild;
  CanvasItemState? get firstChild => _firstChild;
  CanvasItemState? get lastChild => _lastChild;

  // Create a copy of the linked list of children
  CanvasItemNode? get firstChildNode {
    var child = _firstChild;
    CanvasItemNode? first;
    CanvasItemNode? last;

    void append(CanvasItemState item) {
      if (last != null) {
        last!.next = CanvasItemNode(item, null);
        last = last!.next;
      } else {
        first = last = CanvasItemNode(item, null);
      }
    }

    while (child != null) {
      append(child);
      child = child.parentData.nextSibling;
    }

    return first;
  }

  @override
  void requestRelayout() {
    var parent = this.parent;
    if (parent != null) {
      parent.markNeedsLayout();
    }
    markNeedsLayout();
  }

  @override
  void requestChildRelayout(CanvasItemState child) {
    item.layout.visitRelayout(this, child);
  }

  @override
  void markNeedsLayout() {
    notifyListeners();
  }

  @override
  void dispose() {
    buildChildren(const []);
    super.dispose();
  }

  void buildChildren(List<CanvasItem> newChildren) {
    print('building children for ${item.debugLabel}');
    var oldNode = firstChildNode;
    CanvasItemState? findExistingChild(CanvasItem item) {
      for (var child in LinkedNodeIterable(oldNode)) {
        if (child.item.item == item) {
          return child.item;
        }
      }
      return null;
    }

    for (var oldChild in LinkedNodeIterable(oldNode)) {
      oldChild.item.parent = null;
    }

    CanvasItemState? newFirstChild;
    CanvasItemState? newLastChild;
    void append(CanvasItemState itemState) {
      newFirstChild ??= itemState;
      if (newLastChild != null) {
        newLastChild!.parentData.nextSibling = itemState;
      }
      itemState.parentData.previousSibling = newLastChild;
      newLastChild = itemState;
      itemState.parent = this;
    }

    for (var child in newChildren) {
      var existing = findExistingChild(child);
      if (existing != null) {
        append(existing);
        print('append existing child ${existing.item.debugLabel}');
      } else {
        var newState = child.createState(parent: this);
        print('append new child ${newState.item.debugLabel}');
        child.attach(newState);
        append(newState);
      }
    }

    for (var oldChild in LinkedNodeIterable(oldNode)) {
      if (oldChild.item.parent == null) {
        print('detach child ${oldChild.item.item.debugLabel}');
        oldChild.item.item.detach(oldChild.item);
        oldChild.item.dispose();
      }
    }

    _firstChild = newFirstChild;
    _lastChild = newLastChild;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return item.layout.computeMinIntrinsicWidth(this, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return item.layout.computeMaxIntrinsicWidth(this, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return item.layout.computeMinIntrinsicHeight(this, width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return item.layout.computeMaxIntrinsicHeight(this, width);
  }

  @override
  Size forceLayout(BoxConstraints constraints, TextDirection textDirection) {
    return item.layout.performLayout(this, constraints, textDirection);
  }

  @override
  String toString() {
    return 'CanvasObjectState{item: $item}';
  }
}

class CanvasRoot extends CanvasObject {
  CanvasRoot({
    super.layout,
    super.layoutData,
    super.children,
    super.debugLabel,
  });

  @override
  CanvasItemState createState({CanvasItemState? parent}) {
    return RootCanvasItemState(
      parent: parent,
      item: this,
    );
  }
}

class RootCanvasItemState extends CanvasObjectState {
  RootCanvasItemState({
    super.parent,
    required CanvasRoot super.item,
  });
}

abstract class LinkedNode<T extends LinkedNode<T>> {
  T? get next;
}

class LinkedNodeIterator<T extends LinkedNode<T>> implements Iterator<T> {
  final T? _firstNode;
  bool _first = true;
  T? _current;

  LinkedNodeIterator(this._firstNode) : _current = _firstNode;

  @override
  T get current {
    assert(_current != null, 'No current node');
    return _current!;
  }

  @override
  bool moveNext() {
    if (_first) {
      _first = false;
      return _firstNode != null;
    }
    if (_current == null) return false;
    _current = _current!.next;
    return _current != null;
  }
}

class LinkedNodeIterable<T extends LinkedNode<T>> extends Iterable<T> {
  final T? _firstNode;

  LinkedNodeIterable(this._firstNode);

  @override
  Iterator<T> get iterator => LinkedNodeIterator(_firstNode);
}
