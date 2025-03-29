import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  bool _clipContent;
  @override
  List<CanvasObjectState> get _attachedStates =>
      super._attachedStates.cast<CanvasObjectState>();

  CanvasObject({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
    super.debugLabel,
    bool clipContent = true,
  })  : _layout = layout,
        _layoutData = layoutData,
        _children = List.of(children),
        _clipContent = clipContent;

  bool get clipContent => _clipContent;
  set clipContent(bool value) {
    if (value != _clipContent) {
      _clipContent = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }

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

  // helper methods with children
  void addChild(CanvasItem child) {
    children = [..._children, child];
  }

  void insertChild(int index, CanvasItem child) {
    var newChildren = List.of(_children);
    newChildren.insert(index, child);
    children = newChildren;
  }

  void removeChild(CanvasItem child) {
    children = _children.where((e) => e != child).toList();
  }

  void removeChildAt(int index) {
    var newChildren = List.of(_children);
    newChildren.removeAt(index);
    children = newChildren;
  }
  // end

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

abstract class CanvasItemState implements Listenable, HitTestTarget {
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

  Offset get globalShear {
    Offset currentShear = item.layoutData.shear ?? Offset.zero;
    CanvasItemState? current = this;
    while (current != null) {
      var parent = current.parent;
      if (parent != null) {
        currentShear += parent.item.layoutData.shear ?? Offset.zero;
      }
      current = parent;
    }
    return currentShear;
  }

  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (hitTestSelf(result, position)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  bool hitTestSelf(CanvasHitTestResult result, Offset position) {
    return size.containsIgnoreSign(position);
  }

  void selectTest(CanvasHitTestResult result, Polygon polygon) {
    selectTestSelf(result, polygon);
  }

  void selectTestSelf(CanvasHitTestResult result, Polygon polygon) {
    Polygon self = Polygon.fromRect(Offset.zero & size);
    PolygonOverlapResult hit = polygon.overlap(self);
    if (hit != PolygonOverlapResult.none) {
      result.add(CanvasPolygonHitTestEntry(this, hit));
    }
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {}

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

  bool isAfterThis(CanvasItemState state) {
    CanvasItemState? next = state.parentData.nextSibling;
    while (next != null) {
      if (next == this) {
        return true;
      }
      next = next.parentData.nextSibling;
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
        _layoutResult!.constraints.equalsIgnoreSign(constraints) &&
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
      print('layout: ${item.debugLabel} -> $size');
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
  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (hitTestChildren(result, position) || hitTestSelf(result, position)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  bool hitTestChildren(CanvasHitTestResult result, Offset position) {
    if (item.clipContent) {
      if (!size.containsIgnoreSign(position)) {
        return false;
      }
    }
    var child = lastChild;
    while (child != null) {
      var childTransform = child.item.layoutData.computeTranslatedMatrix(
        child,
        child.size,
      );
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
  void selectTest(CanvasHitTestResult result, Polygon polygon) {
    selectTestSelf(result, polygon);
    selectTestChildren(result, polygon);
  }

  void selectTestChildren(CanvasHitTestResult result, Polygon polygon) {
    if (item.clipContent) {
      Polygon self = Polygon.fromRect(Offset.zero & size);
      polygon = polygon.intersect(self);
    }
    var child = lastChild;
    while (child != null) {
      var childTransform = child.item.layoutData.computeTranslatedMatrix(
        child,
        child.size,
      );
      result.addWithPaintTransformPolygon(
        transform: childTransform,
        polygon: polygon,
        hitTest: (result, polygon) {
          child!.selectTest(result, polygon);
        },
      );
      child = child.parentData.previousSibling;
    }
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

  void _validateNonCircularSiblings(CanvasItemState child) {
    List<CanvasItemState> visited = [];
    CanvasItemState? next = child;
    while (next != null) {
      if (visited.contains(next)) {
        throw StateError(
            'Circular sibling detected for ${child.item.debugLabel} (visited: $visited)');
      }
      visited.add(next);
      next = next.parentData.nextSibling;
    }
  }

  void _validateNonCircularChildren() {
    for (var child in children) {
      _validateNonCircularSiblings(child);
    }
  }

  void buildChildren(List<CanvasItem> newChildren) {
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
      // clean
      itemState.parentData.nextSibling = null;
      itemState.parentData.previousSibling = null;
      //
      newFirstChild ??= itemState;
      if (newLastChild != null) {
        newLastChild!.parentData.nextSibling = itemState;
        itemState.parentData.previousSibling = newLastChild;
      }
      newLastChild = itemState;
      itemState.parent = this;
    }

    for (var child in newChildren) {
      var existing = findExistingChild(child);
      if (existing != null) {
        append(existing);
      } else {
        var newState = child.createState(parent: this);
        child.attach(newState);
        append(newState);
      }
    }

    for (var oldChild in LinkedNodeIterable(oldNode)) {
      if (oldChild.item.parent == null) {
        oldChild.item.item.detach(oldChild.item);
        oldChild.item.dispose();
      }
    }

    _firstChild = newFirstChild;
    _lastChild = newLastChild;

    assert(() {
      _validateNonCircularChildren();
      return true;
    }());
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
  }) : super(
            clipContent:
                false); // NEVER clip content root because root has always zero size

  @override
  CanvasRootState createState({CanvasItemState? parent}) {
    return CanvasRootState(
      parent: parent,
      item: this,
    );
  }
}

class CanvasRootState extends CanvasObjectState {
  CanvasRootState({
    super.parent,
    required CanvasRoot super.item,
  });

  @override
  bool hitTestSelf(CanvasHitTestResult result, Offset position) {
    return false;
  }

  @override
  bool selectTestSelf(CanvasHitTestResult result, Polygon polygon) {
    return false;
  }
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

typedef CanvasHitTest = bool Function(
    CanvasHitTestResult result, Offset position);

typedef CanvasHitTestPolygon = void Function(
    CanvasHitTestResult result, Polygon polygon);

class CanvasHitTestResult extends HitTestResult {
  CanvasHitTestResult() : super();

  @override
  Iterable<HitTestEntry<CanvasItemState>> get path =>
      super.path.cast<HitTestEntry<CanvasItemState>>();

  bool addWithRawTransform({
    required Matrix4? transform,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    final Offset transformedPosition = transform == null
        ? position
        : MatrixUtils.transformPoint(transform, position);
    if (transform != null) {
      pushTransform(transform);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (transform != null) {
      popTransform();
    }
    return isHit;
  }

  bool addWithPaintTransform({
    required Matrix4? transform,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return false;
      }
    }
    return addWithRawTransform(
        transform: transform, position: position, hitTest: hitTest);
  }

  void addWithRawTransformPolygon({
    required Matrix4? transform,
    required Polygon polygon,
    required CanvasHitTestPolygon hitTest,
  }) {
    final Polygon transformedPolygon =
        transform == null ? polygon : polygon.transform(transform);
    if (transform != null) {
      pushTransform(transform);
    }
    hitTest(this, transformedPolygon);
    if (transform != null) {
      popTransform();
    }
  }

  void addWithPaintTransformPolygon({
    required Matrix4? transform,
    required Polygon polygon,
    required CanvasHitTestPolygon hitTest,
  }) {
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return;
      }
    }
    addWithRawTransformPolygon(
        transform: transform, polygon: polygon, hitTest: hitTest);
  }

  bool addWithPaintOffset({
    required Offset? offset,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    final Offset transformedPosition =
        offset == null ? position : position - offset;
    if (offset != null) {
      pushOffset(-offset);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (offset != null) {
      popTransform();
    }
    return isHit;
  }

  void addWithPaintOffsetPolygon({
    required Offset? offset,
    required Polygon polygon,
    required CanvasHitTestPolygon hitTest,
  }) {
    final Polygon transformedPolygon =
        offset == null ? polygon : polygon.translate(-offset);
    if (offset != null) {
      pushOffset(-offset);
    }
    hitTest(this, transformedPolygon);
    if (offset != null) {
      popTransform();
    }
  }
}

class CanvasHitTestEntry extends HitTestEntry<CanvasItemState> {
  final Offset localPosition;
  CanvasHitTestEntry(super.target, this.localPosition);
  @override
  String toString() {
    return 'CanvasHitTestEntry(target: $target, localPosition: $localPosition)';
  }
}

class CanvasPolygonHitTestEntry extends HitTestEntry<CanvasItemState> {
  final PolygonOverlapResult overlap;
  CanvasPolygonHitTestEntry(super.target, this.overlap);

  @override
  String toString() {
    return 'CanvasPolygonHitTestEntry(target: $target, overlap: $overlap)';
  }
}

enum DirectionalCursor {
  top(SystemMouseCursors.resizeUpDown), // 0
  topRight(SystemMouseCursors.resizeUpRight), // 45
  right(SystemMouseCursors.resizeLeftRight), // 90
  bottomRight(SystemMouseCursors.resizeDownRight), // 135
  bottom(SystemMouseCursors.resizeUpDown), // 180
  bottomLeft(SystemMouseCursors.resizeDownLeft), // 225
  left(SystemMouseCursors.resizeLeftRight), // 270
  topLeft(SystemMouseCursors.resizeUpLeft); // 315

  static const length = 8; // number of directions
  static const double angleStep = 2 * pi / length; // = 45 degrees

  final MouseCursor cursor;

  const DirectionalCursor(this.cursor);

  DirectionalCursor rotate(int count) {
    int index = (this.index + count) % length;
    return DirectionalCursor.values[index];
  }

  DirectionalCursor rotateByAngle(double angle) {
    int index = ((this.index + (angle / angleStep).round()) % length).toInt();
    return DirectionalCursor.values[index];
  }

  DirectionalCursor flip({bool horizontal = false, bool vertical = false}) {
    DirectionalCursor current = this;
    if (horizontal) {
      switch (current) {
        case DirectionalCursor.topLeft:
          current = DirectionalCursor.topRight;
          break;
        case DirectionalCursor.topRight:
          current = DirectionalCursor.topLeft;
          break;
        case DirectionalCursor.bottomLeft:
          current = DirectionalCursor.bottomRight;
          break;
        case DirectionalCursor.bottomRight:
          current = DirectionalCursor.bottomLeft;
          break;
        case DirectionalCursor.left:
          current = DirectionalCursor.right;
          break;
        case DirectionalCursor.right:
          current = DirectionalCursor.left;
          break;
        default:
          break;
      }
    }
    if (vertical) {
      switch (current) {
        case DirectionalCursor.topLeft:
          current = DirectionalCursor.bottomLeft;
          break;
        case DirectionalCursor.topRight:
          current = DirectionalCursor.bottomRight;
          break;
        case DirectionalCursor.bottomLeft:
          current = DirectionalCursor.topLeft;
          break;
        case DirectionalCursor.bottomRight:
          current = DirectionalCursor.topRight;
          break;
        case DirectionalCursor.left:
          current = DirectionalCursor.right;
          break;
        case DirectionalCursor.right:
          current = DirectionalCursor.left;
          break;
        default:
          break;
      }
    }
    return current;
  }
}
