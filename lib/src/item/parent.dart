import 'package:canvas/canvas.dart';
import 'package:canvas/src/collections.dart';
import 'package:canvas/src/editor/grid/grid.dart';
import 'package:canvas/src/editor/selection/selection.dart';
import 'package:canvas/src/item/base.dart';
import 'package:canvas/src/item/widget/base.dart';
import 'package:canvas/src/item/widget/parent.dart';
import 'package:canvas/src/layout/fixed.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class BaseCanvasParent extends BaseCanvasItem implements CanvasParent {
  List<CanvasItem> _children;
  CanvasLayout _layout;
  List<LayoutGrid> _layoutGrids;
  bool _clipContent = false;

  BaseCanvasParent({
    super.layoutData,
    super.locked,
    super.overflow,
    List<CanvasItem> children = const [],
    CanvasLayout layout = const FixedLayout(),
    List<LayoutGrid> layoutGrids = const [],
    bool clipContent = false,
    super.debugLabel,
  })  : _children = List.of(children),
        _layout = layout,
        _layoutGrids = List.of(layoutGrids),
        _clipContent = clipContent;

  @override
  bool get clipContent => _clipContent;

  @override
  set clipContent(bool value) {
    if (_clipContent != value) {
      _clipContent = value;
      notifyStates();
    }
  }

  @override
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

  @override
  List<CanvasItem> get children => List.unmodifiable(_children);

  @override
  set layout(CanvasLayout value) {
    if (_layout != value) {
      _layout = value;
      notifyStates();
    }
  }

  @override
  CanvasLayout get layout => _layout;

  @override
  set layoutGrids(List<LayoutGrid> value) {
    if (!listEquals(_layoutGrids, value)) {
      _layoutGrids = List.of(value);
      notifyStates();
    }
  }

  @override
  List<LayoutGrid> get layoutGrids => List.unmodifiable(_layoutGrids);

  @override
  List<BaseCanvasParentState> get attachedStates {
    return super.attachedStates.cast<BaseCanvasParentState>();
  }

  @override
  BaseCanvasParentState createState({CanvasParentState? parent}) {
    return BaseCanvasParentState(item: this, parent: parent);
  }

  @override
  void detach(covariant BaseCanvasParentState state) {
    super.detach(state);
  }

  @override
  void attach(covariant BaseCanvasParentState state) {
    super.attach(state);
    var parent = state.parent;
    if (parent is CanvasParentState) {
      var layout = parent.item.layout;
      var oldParentData = state.unmountableParentData;
      var newParentData = layout.setupParentData(parent, state, oldParentData);
      state.unmountableParentData = newParentData;
    } else {
      state.unmountableParentData = CanvasParentData();
    }
    state.buildChildren(_children);
  }

  @override
  void addChild(CanvasItem child) {
    _children.add(child);
    notifyChildrenChanged();
  }

  @override
  void removeChild(CanvasItem child) {
    if (_children.remove(child)) {
      notifyChildrenChanged();
    }
  }

  @override
  void insertChild(int index, CanvasItem child) {
    _children.insert(index, child);
    notifyChildrenChanged();
  }

  @override
  void clearChildren() {
    _children.clear();
    notifyChildrenChanged();
  }

  @override
  void removeChildAt(int index) {
    if (index >= 0 && index < _children.length) {
      _children.removeAt(index);
      notifyChildrenChanged();
    } else {
      throw RangeError.index(index, _children, 'index out of range');
    }
  }

  @override
  void insertBefore(CanvasItem child, CanvasItem beforeChild) {
    var index = _children.indexOf(beforeChild);
    if (index == -1) {
      throw ArgumentError('beforeChild not found in children');
    }
    _children.insert(index, child);
    notifyChildrenChanged();
  }
}

class BaseCanvasParentState extends BaseCanvasItemState
    implements CanvasParentState {
  LinkedNode<CanvasItemState>? _firstChildNode;
  LinkedNode<CanvasItemState>? _lastChildNode;

  BaseCanvasParentState(
      {required BaseCanvasParent super.item, required super.parent});

  @override
  Widget render(BuildContext context, {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: CanvasParentWidget(
        item: this,
        child: renderContent(context),
      ),
    );
  }

  @override
  Widget renderEditor(BuildContext context, CanvasEditor editor,
      {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: CanvasParentWidget(
        item: this,
        child: CanvasItemEditorWidget(
          item: this,
          editor: editor,
          child: renderContent(context),
        ),
      ),
    );
  }

  @override
  CanvasParentItemEditorData get editorData =>
      super.editorData as CanvasParentItemEditorData;

  @override
  set editorData(CanvasParentItemEditorData value) {
    super.editorData = value;
  }

  @override
  void forceLayout(Size size) {
    item.layout.performLayout(this, size);
    super.forceLayout(size);
  }

  @override
  List<CanvasItemState> get children =>
      _firstChildNode?.map((e) => e.value).toList() ?? [];

  @override
  set children(List<CanvasItemState> value) {
    item.children = value.map((e) => e.item).toList();
  }

  @override
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

  @override
  Axis analyzePossibleFlexDirection() {
    throw UnimplementedError();
  }

  @override
  EdgeInsets analyzePossiblePadding() {
    throw UnimplementedError();
  }

  @override
  double analyzePossibleSpacing() {
    throw UnimplementedError();
  }

  @override
  CanvasItemState? get firstChild => _firstChildNode?.value;

  @override
  LinkedNode<CanvasItemState>? get firstChildNode => _firstChildNode;

  @override
  bool hitTestChildren(CanvasHitTestResult result, Offset position) {
    if (editorData.dragOffset != null) {
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

  @override
  CanvasItemState? get lastChild => _lastChildNode?.value;

  @override
  LinkedNode<CanvasItemState>? get lastChildNode => _lastChildNode;

  @override
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

  @override
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

  @override
  void putReorderOffset(CanvasItemState child, double offset) {
    Map<CanvasItemState, double> reorderOffsetMap = Map.of(
      editorData.reorderOffsetMap,
    );
    reorderOffsetMap[child] = offset;
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  void removeReorderOffset(CanvasItemState child) {
    Map<CanvasItemState, double> reorderOffsetMap = Map.of(
      editorData.reorderOffsetMap,
    );
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  void clearReorderOffsets() {
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: const {},
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  Offset? get reorderOffsets {
    Map<CanvasItemState, double> reorderOffsetMap = editorData.reorderOffsetMap;
    var parent = this.parent;
    var parentLayout = parent?.item.layout;
    if (parentLayout is FlexLayout) {
      var direction = parentLayout.direction;
      if (direction == Axis.horizontal) {
        return Offset(
          reorderOffsetMap.values.reduce((a, b) => a + b),
          0,
        );
      } else {
        return Offset(
          0,
          reorderOffsetMap.values.reduce((a, b) => a + b),
        );
      }
    }
    return null;
  }

  @override
  set targetReorderIndex(int? value) {
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: value,
    );
  }

  @override
  int? get targetReorderIndex => editorData.targetReorderIndex;

  @override
  CanvasParentState? get targetReparent => editorData.targetReparent;

  @override
  set targetReparent(CanvasParentState? value) {
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: value,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  set dragOffset(Offset? value) {
    editorData = CanvasParentItemEditorData(
      targetDrop: editorData.targetDrop,
      dragOffset: value,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  Offset? get dragOffset => editorData.dragOffset;

  @override
  Selection? get targetDrop => editorData.targetDrop;

  @override
  set targetDrop(Selection? value) {
    editorData = CanvasParentItemEditorData(
      targetDrop: value,
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }
}
