import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CanvasParent extends CanvasItem {
  List<CanvasItem> _children;

  CanvasParent({
    super.layoutData,
    super.locked,
    super.overflow,
    List<CanvasItem> children = const [],
    super.debugLabel,
  }) : _children = List.of(children);

  CanvasFrame? convertToFrame() {
    return null;
  }

  // TODO: convertToGroup

  set children(List<CanvasItem> value) {
    if (!listEquals(_children, value)) {
      _children = List.of(value);
      notifyChildrenChanged();
    }
  }

  void notifyChildrenChanged() {
    for (var state in attachedStates) {
      state.buildChildren(_children);
      state.notify();
    }
  }

  List<CanvasItem> get children => List.unmodifiable(_children);

  @override
  List<CanvasParentState> get attachedStates {
    return super.attachedStates.cast<CanvasParentState>();
  }

  @override
  CanvasParentState createState({CanvasParentState? parent}) {
    return CanvasParentState(item: this, parent: parent);
  }

  @override
  void detach(covariant CanvasParentState state) {
    super.detach(state);
  }

  @override
  void attach(covariant CanvasParentState state) {
    super.attach(state);
    var parent = state.parent;
    var oldParentData = state.unmountableParentData;
    var newParentData =
        parent?.setupParentData(state, oldParentData) ?? CanvasParentData();
    state.unmountableParentData = newParentData;
    state.buildChildren(_children);
  }

  void addChild(CanvasItem child) {
    _children.add(child);
    notifyChildrenChanged();
  }

  void removeChild(CanvasItem child) {
    if (_children.remove(child)) {
      notifyChildrenChanged();
    }
  }

  void insertChild(int index, CanvasItem child) {
    _children.insert(index, child);
    notifyChildrenChanged();
  }

  void clearChildren() {
    _children.clear();
    notifyChildrenChanged();
  }

  void removeChildAt(int index) {
    if (index >= 0 && index < _children.length) {
      _children.removeAt(index);
      notifyChildrenChanged();
    } else {
      throw RangeError.index(index, _children, 'index out of range');
    }
  }

  void insertBefore(CanvasItem child, CanvasItem beforeChild) {
    var index = _children.indexOf(beforeChild);
    if (index == -1) {
      throw ArgumentError('beforeChild not found in children');
    }
    _children.insert(index, child);
    notifyChildrenChanged();
  }
}

class CanvasParentState extends CanvasItemState {
  LinkedNode<CanvasItemState>? _firstChildNode;
  LinkedNode<CanvasItemState>? _lastChildNode;

  CanvasParentState({required CanvasParent super.item, required super.parent});

  Selection? _targetDrop;

  bool acceptReparent(CanvasItemState child) {
    return true;
  }

  CanvasParentData setupParentData(
      CanvasItemState child, CanvasParentData? parentData) {
    return parentData ?? CanvasParentData();
  }

  @override
  Widget render(BuildContext context, {Matrix4? transform}) {
    final content = renderContent(context);
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: ListenableBuilder(
        listenable: this,
        builder: (context, child) {
          return renderParent(
            context,
            [
              if (content != null)
                AdaptiveSizedBox(
                  size: size,
                  child: content,
                ),
              for (var child in children.sorted(sortChildren))
                child.render(context),
            ],
          );
        },
      ),
    );
  }

  Widget renderParent(BuildContext context, List<Widget> children) {
    return CanvasParentWidget(
      item: this,
      children: children,
    );
  }

  @override
  Widget renderEditor(BuildContext context, CanvasEditor editor,
      {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: ListenableBuilder(
        listenable: this,
        builder: (context, child) {
          return renderParent(
            context,
            [
              CanvasItemEditorWidget(
                item: this,
                editor: editor,
                child: AdaptiveSizedBox(
                  size: size,
                  child: renderContent(context) ?? const SizedBox.shrink(),
                ),
              ),
              for (var child in children.sorted(sortChildren))
                child.renderEditor(context, editor),
            ],
          );
        },
      ),
    );
  }

  List<CanvasItemState> get children =>
      _firstChildNode?.map((e) => e.value).toList() ?? [];

  set children(List<CanvasItemState> value) {
    item.children = value.map((e) => e.item).toList();
  }

  void buildChildren(List<CanvasItem> children) {
    var oldNode = firstChildNode;
    CanvasItemState? findExistingChild(CanvasItem item) {
      if (oldNode != null) {
        for (var child in oldNode) {
          if (child.value.item == item) {
            return child.value;
          }
        }
      }
      return null;
    }

    if (oldNode != null) {
      for (var child in oldNode) {
        child.value.markForDisposal();
      }
    }

    LinkedNode<CanvasItemState>? newLastChildNode;

    for (var child in children) {
      var existing = findExistingChild(child);
      if (existing != null) {
        existing.markForRebuild();
        if (newLastChildNode == null) {
          newLastChildNode = LinkedNode<CanvasItemState>(existing);
        } else {
          var node = LinkedNode<CanvasItemState>(existing);
          newLastChildNode.next = node;
          newLastChildNode = node;
        }
      } else {
        var newState = child.createState(parent: this);
        child.attach(newState);
        if (newLastChildNode == null) {
          newLastChildNode = LinkedNode<CanvasItemState>(newState);
        } else {
          var node = LinkedNode<CanvasItemState>(newState);
          newLastChildNode.next = node;
          newLastChildNode = node;
        }
      }
    }

    if (newLastChildNode != null) {
      for (var node in newLastChildNode.reversed) {
        node.value.parentData.nextSibling = node.next?.value;
        node.value.parentData.previousSibling = node.previous?.value;
      }
    }

    if (oldNode != null) {
      for (var oldChild in oldNode) {
        if (oldChild.value.markedForDisposal) {
          oldChild.value.item.detach(oldChild.value);
          oldChild.value.dispose();
        }
      }
    }

    _firstChildNode = newLastChildNode?.first;
    _lastChildNode = newLastChildNode?.last;

    assert(() {
      _validateNonCircularChildren();
      return true;
    }());
  }

  void _validateNonCircularChildren() {
    var current = _firstChildNode;
    if (current != null) {
      for (var child in current) {
        _validateNonCircularSiblings(child.value);
      }
    }
  }

  @override
  bool visitSnapAnchor(SnapAnchorVisitor visitor, {Matrix4? parentTransform}) {
    if (dragOffset != null || parentHasEditorOffset || !item.allowSnapping) {
      return true;
    }
    if (!super.visitSnapAnchor(visitor, parentTransform: parentTransform)) {
      return false;
    }
    var child = firstChild;
    while (child != null) {
      if (!child.visitSnapAnchor(visitor,
          parentTransform:
              computeTransform(parentTransform: parentTransform))) {
        return false;
      }
      child = child.parentData.nextSibling;
    }
    return true;
  }

  void _validateNonCircularSiblings(CanvasItemState child) {
    LinkedNode<CanvasItemState>? visitedNode;
    CanvasItemState? next = child;
    while (next != null) {
      if (visitedNode != null && visitedNode.siblingsContains(next)) {
        throw Exception('Circular reference detected in siblings: $next');
      }
      if (visitedNode == null) {
        visitedNode = LinkedNode<CanvasItemState>(next);
      } else {
        var node = LinkedNode<CanvasItemState>(next);
        visitedNode.next = node;
        visitedNode = node;
      }
      next = next.parentData.nextSibling;
    }
  }

  @override
  CanvasParent get item => super.item as CanvasParent;

  Axis analyzePossibleFlexDirection() {
    if (firstChildNode == null) {
      return Axis.horizontal;
    }
    double maxWidth = double.negativeInfinity;
    double maxHeight = double.negativeInfinity;
    var child = firstChild;
    while (child != null) {
      var position = child.parentData.position;
      var size = child.size;
      maxWidth = max(maxWidth, position.dx + size.width);
      maxHeight = max(maxHeight, position.dy + size.height);
      child = child.parentData.nextSibling;
    }
    if (maxWidth > maxHeight) {
      return Axis.horizontal;
    } else {
      return Axis.vertical;
    }
  }

  EdgeInsets analyzePossiblePadding() {
    if (firstChildNode == null) {
      return EdgeInsets.zero;
    }
    double minTop = double.infinity;
    double minLeft = double.infinity;
    double minRight = double.infinity;
    double minBottom = double.infinity;
    var child = firstChild;
    while (child != null) {
      var position = child.parentData.position;
      var size = child.size;
      minTop = min(minTop, position.dy);
      minLeft = min(minLeft, position.dx);
      minRight = min(minRight, size.width - position.dx - size.width);
      minBottom = min(minBottom, size.height - position.dy - size.height);
      child = child.parentData.nextSibling;
    }
    return EdgeInsets.only(
      top: max(0, minTop),
      left: max(0, minLeft),
      right: max(0, minRight),
      bottom: max(0, minBottom),
    );
  }

  double analyzePossibleSpacing() {
    if (firstChildNode == null || firstChildNode?.next == null) {
      return 0;
    }
    double minSpacing = double.infinity;
    var child = firstChild;
    while (child != null) {
      var nextSibling = child.parentData.nextSibling;
      if (nextSibling != null) {
        var position = child.parentData.position;
        var nextPosition = nextSibling.parentData.position;
        var size = child.size;
        var nextSize = nextSibling.size;
        var rect = position & size;
        var nextRect = nextPosition & nextSize;
        if (!rect.overlaps(nextRect)) {
          var distance = distanceBetweenRects(rect, nextRect);
          if (distance < minSpacing) {
            minSpacing = distance;
          }
        }
      }
      child = nextSibling;
    }
    return minSpacing == double.infinity ? 0 : max(0, minSpacing);
  }

  CanvasItemState? get firstChild => _firstChildNode?.value;

  LinkedNode<CanvasItemState>? get firstChildNode => _firstChildNode;

  bool hitTestChildren(CanvasHitTestResult result, Offset position) {
    if (dragOffset != null) {
      return false;
    }
    var child = lastChild;
    while (child != null) {
      var childTransform = child.computeTransform();
      final isHit = result.addWithPaintTransform(
        transform: childTransform,
        position: position,
        hitTest: (result, position) {
          return child!.hitTest(result, position);
        },
      );
      if (isHit) {
        return true;
      }
      child = child.parentData.previousSibling;
    }
    return false;
  }

  CanvasItemState? get lastChild => _lastChildNode?.value;

  LinkedNode<CanvasItemState>? get lastChildNode => _lastChildNode;

  void reorderItem(CanvasItemState child, int newIndex) {
    var children = List.of(item.children);
    var oldIndex = children.indexOf(child.item);
    assert(oldIndex != -1, 'Child not found in parent: $child');
    assert(newIndex >= 0 && newIndex < children.length,
        'New index out of bounds: $newIndex');
    if (oldIndex != newIndex) {
      if (oldIndex < newIndex) {
        for (var i = oldIndex; i < newIndex; i++) {
          children[i] = children[i + 1];
        }
        children[newIndex] = child.item;
      } else {
        for (var i = oldIndex; i > newIndex; i--) {
          children[i] = children[i - 1];
        }
        children[newIndex] = child.item;
      }
      item.children = children;
    }
  }

  @override
  void selectTest(CanvasHitTestResult result, Path path) {
    super.selectTest(result, path);
    selectTestChildren(result, path);
  }

  void selectTestChildren(CanvasHitTestResult result, Path path) {
    var child = lastChild;
    while (child != null) {
      var childTransform = child.computeTransform();
      result.addWithPaintTransformPath(
        transform: childTransform,
        path: path,
        hitTest: (result, path) {
          child!.selectTest(result, path);
        },
      );
      child = child.parentData.previousSibling;
    }
  }

  @override
  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (!super.hitTest(result, position)) {
      if (hitTestChildren(result, position)) {
        return true;
      }
    }
    return false;
  }

  set targetDrop(Selection? value) {
    if (_targetDrop != value) {
      _targetDrop = value;
      notify();
    }
  }

  Selection? get targetDrop => _targetDrop;
}
