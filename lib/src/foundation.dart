import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/debug.dart';
import 'package:canvas/src/editor/extra.dart';
import 'package:canvas/src/editor/grid.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum CanvasChildOperation {
  intersection,
  subtraction,
  reverseSubtraction,
  symmetricDifference, // reversed intersection
}

enum CanvasOverflow {
  hide,
  visible,
  scroll,
}

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

  CanvasItemState createState(
      {CanvasItemState? parent, CanvasEditorHandler? editor});

  List<CanvasItemState> get activeStates => List.unmodifiable(_attachedStates);
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
  BorderRadiusGeometry? _borderRadius;
  @override
  List<CanvasObjectState> get _attachedStates =>
      super._attachedStates.cast<CanvasObjectState>();

  List<LayoutGrid> _layoutGrids = [];

  CanvasObject({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
    List<LayoutGrid> layoutGrids = const [],
    super.debugLabel,
    bool clipContent = true,
    BorderRadiusGeometry? borderRadius,
  })  : _layout = layout,
        _layoutData = layoutData,
        _children = List.of(children),
        _clipContent = clipContent,
        _layoutGrids = layoutGrids,
        _borderRadius = borderRadius;

  BorderRadiusGeometry? get borderRadius => _borderRadius;
  set borderRadius(BorderRadiusGeometry? value) {
    if (value != _borderRadius) {
      _borderRadius = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }

  bool get clipContent => _clipContent;
  set clipContent(bool value) {
    if (value != _clipContent) {
      _clipContent = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }

  List<LayoutGrid> get layoutGrids => List.unmodifiable(_layoutGrids);
  set layoutGrids(List<LayoutGrid> value) {
    if (!listEquals(value, _layoutGrids)) {
      _layoutGrids = List.of(value);
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }

  @override
  CanvasItemState createState(
      {CanvasItemState? parent, CanvasEditorHandler? editor}) {
    return CanvasObjectState(
      parent: parent,
      item: this,
      editor: editor,
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
      _children = List.of(value);
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

  // helper methods with layout grids
  void addLayoutGrid(LayoutGrid grid) {
    layoutGrids = [..._layoutGrids, grid];
  }

  void insertLayoutGrid(int index, LayoutGrid grid) {
    var newGrids = List.of(_layoutGrids);
    newGrids.insert(index, grid);
    layoutGrids = newGrids;
  }

  void removeLayoutGrid(LayoutGrid grid) {
    layoutGrids = _layoutGrids.where((e) => e != grid).toList();
  }

  void removeLayoutGridAt(int index) {
    var newGrids = List.of(_layoutGrids);
    newGrids.removeAt(index);
    layoutGrids = newGrids;
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
  final Rect preferredBounds; // used to make the item scrollable

  _CachedLayout({
    required this.size,
    required this.constraints,
    required this.textDirection,
    required this.preferredBounds,
  });
}

abstract class CanvasItemState implements Listenable, HitTestTarget {
  CanvasItemState? parent;
  CanvasItem get item;
  CanvasParentData? _parentData;
  _CachedLayout? _layoutResult;
  final CanvasEditorHandler? editor;

  // Editor specific properties
  Offset? _editorOffset;
  Offset? get editorOffset => _editorOffset;
  set editorOffset(Offset? value) {
    if (value != _editorOffset) {
      _editorOffset = value;
      markNeedsLayout();
    }
  }

  CanvasObjectState? _targetReparent;
  CanvasObjectState? get targetReparent => _targetReparent;
  set targetReparent(CanvasObjectState? value) {
    if (_targetReparent != value) {
      _targetReparent = value;
      markNeedsLayout();
    }
  }
  //

  CanvasItemState({this.parent, this.editor});

  CanvasParentData get parentData {
    var parentData = _parentData;
    assert(parentData != null, 'Parent data not set');
    return parentData!;
  }

  Matrix4 get globalTransform {
    Matrix4 transform = item.layoutData.computeTranslatedMatrix(this);
    CanvasItemState? current = parent;
    while (current != null) {
      transform =
          current.item.layoutData.computeTranslatedMatrix(current) * transform;
      current = current.parent;
    }
    return transform;
  }

  Matrix4 get globalEditorTransform {
    Matrix4 transform = item.layoutData.computeTranslatedMatrix(this);

    CanvasItemState? current = parent;
    while (current != null) {
      transform =
          current.item.layoutData.computeTranslatedMatrix(current) * transform;
      current = current.parent;
    }
    var editorOffset = this.editorOffset;
    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    return transform;
  }

  Matrix4 getGlobalEditorTransformUntil(CanvasItemState topParent) {
    Matrix4 transform = item.layoutData.computeTranslatedMatrix(this);
    var editorOffset = this.editorOffset;
    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    CanvasItemState? current = parent;
    while (current != null && current != topParent) {
      transform =
          current.item.layoutData.computeTranslatedMatrix(current) * transform;
      current = current.parent;
    }
    return transform;
  }

  Matrix4 get parentTransform {
    Matrix4 transform = Matrix4.identity();
    CanvasItemState? current = parent;
    while (current != null) {
      transform =
          current.item.layoutData.computeTranslatedMatrix(current) * transform;
      current = current.parent;
    }
    return transform;
  }

  Matrix4 get localTransform {
    return item.layoutData.computeTranslatedMatrix(this);
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

  CanvasItemState? findCommonParent(CanvasItemState other) {
    CanvasItemState? current = this;
    while (current != null) {
      CanvasItemState? otherCurrent = other;
      while (otherCurrent != null) {
        if (current == otherCurrent) {
          return current;
        }
        otherCurrent = otherCurrent.parent;
      }
      current = current.parent;
    }
    return null;
  }

  bool visitSnapAnchor(SnapAnchorVisitor visitor,
      {Matrix4? parentTransform, Matrix4? transform}) {
    // if this object or its ascendant is being dragged, then do not snap!
    if (editorOffset != null) {
      return true;
    }
    transform ??= item.layoutData.computeTranslatedMatrix(this);
    if (parentTransform != null) {
      transform = (parentTransform * transform) as Matrix4;
    }
    var innerSize = this.innerSize;
    Offset topLeft = transformOffset(Offset.zero, transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: topLeft))) {
      return false;
    }
    Offset topRight = transformOffset(Offset(innerSize.width, 0), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: topRight))) {
      return false;
    }
    Offset bottomRight =
        transformOffset(Offset(innerSize.width, innerSize.height), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: bottomRight))) {
      return false;
    }
    Offset bottomLeft = transformOffset(Offset(0, innerSize.height), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: bottomLeft))) {
      return false;
    }
    // center
    Offset center = transformOffset(
        Offset(innerSize.width / 2, innerSize.height / 2), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: center))) {
      return false;
    }
    return true;
  }

  Path getPath(TextDirection textDirection) {
    return Path()..addRect(Offset.zero & innerSize);
  }

  // this is build when a single selection is created upon this item
  Iterable<ExtraTransformationControl> buildControls({
    required CanvasEditorHandler editor,
    required SelectionGroup selectionGroup,
    required Matrix4 parentTransform,
  }) sync* {}

  Rect computeViewportBounds({Matrix4? parentTransform}) {
    Polygon polygon = Polygon.fromRect(Offset.zero & innerSize);
    Matrix4 transform = item.layoutData.computeTranslatedMatrix(this);
    if (parentTransform != null) {
      transform = parentTransform * transform;
    }
    polygon = polygon.transform(transform);
    return polygon.boundingBox;
  }

  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (editorOffset != null) {
      // object is being invisible
      return false;
    }
    if (hitTestSelf(result, position)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  Size get innerSize => item.layoutData.computeInnerSize(this);

  bool hitTestSelf(CanvasHitTestResult result, Offset position,
      {CanvasHitTestPredicate? test}) {
    if (editorOffset != null) {
      // object is being invisible
      return false;
    }
    if (test != null) {
      if (!test(this)) {
        return false;
      }
    }
    return innerSize.containsIgnoreSign(position);
  }

  void selectTest(
      CanvasHitTestResult result, Path path, TextDirection textDirection) {
    selectTestSelf(result, path, textDirection);
  }

  void selectTestSelf(
      CanvasHitTestResult result, Path path, TextDirection textDirection) {
    Path self = getPath(textDirection);
    Path combined = Path.combine(PathOperation.intersect, self, path);
    if (combined.computeMetrics().isNotEmpty) {
      Rect rect = combined.getBounds();
      Rect testRect = self.getBounds();
      double rectArea = rect.width * rect.height;
      double testArea = testRect.width * testRect.height;
      PolygonOverlapResult overlap;
      if (rectArea < testArea) {
        overlap = PolygonOverlapResult.partial;
      } else {
        overlap = PolygonOverlapResult.full;
      }
      result.add(CanvasPathHitTestEntry(this, overlap));
    }
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {}

  Widget? render(BuildContext context) => RandomContainer(
        seed: hashCode,
        child: Text('${item.debugLabel}'),
      );

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
        preferredBounds: Offset.zero & size,
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
    super.editor,
    required this.item,
  });

  // Editor specific properties
  final ValueNotifier<Selection?> targetDrop = ValueNotifier(null);
  //

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
  Rect computeViewportBounds({Matrix4? parentTransform}) {
    Polygon polygon = Polygon.fromRect(Offset.zero & innerSize);
    Matrix4 transform = item.layoutData.computeTranslatedMatrix(this);
    if (parentTransform != null) {
      transform = parentTransform * transform;
    }
    polygon = polygon.transform(transform);
    Rect boundingBox = polygon.boundingBox;
    var child = firstChild;
    while (child != null) {
      Rect childBound = child.computeViewportBounds(parentTransform: transform);
      boundingBox = boundingBox.expandToInclude(childBound);
      child = child.parentData.nextSibling;
    }
    return boundingBox;
  }

  @override
  void layout(BoxConstraints constraints, TextDirection textDirection) {
    if (!hasLayoutPerformedFor(constraints, textDirection)) {
      var size = forceLayout(constraints, textDirection);
      var child = firstChild;
      double minX = 0;
      double minY = 0;
      double maxX = size.width;
      double maxY = size.height;
      while (child != null) {
        var childPosition = child.parentData.position;
        var childSize = child.size;
        minX = min(minX, childPosition.dx);
        minY = min(minY, childPosition.dy);
        maxX = max(maxX, childPosition.dx + childSize.width);
        maxY = max(maxY, childPosition.dy + childSize.height);
        child = child.parentData.nextSibling;
      }
      var preferredBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
      _layoutResult = _CachedLayout(
        size: size,
        constraints: constraints,
        textDirection: textDirection,
        preferredBounds: preferredBounds,
      );
    }
  }

  @override
  bool hitTest(CanvasHitTestResult result, Offset position,
      {CanvasHitTestPredicate? test}) {
    if (editorOffset != null) {
      // object is being invisible
      return false;
    }
    if (hitTestChildren(result, position, test: test) ||
        hitTestSelf(result, position, test: test)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  bool hitTestChildren(CanvasHitTestResult result, Offset position,
      {CanvasHitTestPredicate? test}) {
    if (item.clipContent) {
      if (!innerSize.containsIgnoreSign(position)) {
        return false;
      }
    }
    var child = lastChild;
    while (child != null) {
      var childTransform = child.item.layoutData.computeTranslatedMatrix(
        child,
      );
      if (test != null) {
        if (!test(child)) {
          child = child.parentData.previousSibling;
          continue;
        }
      }
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
  void selectTest(
      CanvasHitTestResult result, Path path, TextDirection textDirection) {
    selectTestSelf(result, path, textDirection);
    selectTestChildren(result, path, textDirection);
  }

  void selectTestChildren(
      CanvasHitTestResult result, Path path, TextDirection textDirection) {
    if (item.clipContent) {
      Path self = getPath(textDirection);
      path = Path.combine(PathOperation.intersect, self, path);
    }
    var child = lastChild;
    while (child != null) {
      var childTransform = child.item.layoutData.computeTranslatedMatrix(
        child,
      );
      result.addWithPaintTransformPath(
        transform: childTransform,
        path: path,
        hitTest: (result, polygon) {
          child!.selectTest(result, polygon, textDirection);
        },
      );
      child = child.parentData.previousSibling;
    }
  }

  @override
  bool visitSnapAnchor(SnapAnchorVisitor visitor,
      {Matrix4? parentTransform, Matrix4? transform}) {
    transform ??= item.layoutData.computeTranslatedMatrix(this);
    if (parentTransform != null) {
      transform = (parentTransform * transform) as Matrix4;
    }
    if (!super.visitSnapAnchor(visitor,
        parentTransform: null, transform: transform)) {
      return false;
    }
    for (var child in children) {
      if (!child.visitSnapAnchor(visitor, parentTransform: transform)) {
        return false;
      }
    }
    return true;
  }

  @override
  Path getPath(TextDirection textDirection) {
    var borderRadius = item.borderRadius;
    if (borderRadius == null) return super.getPath(textDirection);
    var resolvedBorderRadius = borderRadius.resolve(textDirection);
    if (resolvedBorderRadius == BorderRadius.zero) {
      return super.getPath(textDirection);
    }
    return Path()
      ..addRRect(resolvedBorderRadius.toRRect(Offset.zero & innerSize));
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
        var newState = child.createState(parent: this, editor: editor);
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
    super.children,
    super.debugLabel,
  }) : super(
            clipContent:
                false); // NEVER clip content root because root has always zero size

  @override
  CanvasRootState createState(
      {CanvasItemState? parent, CanvasEditorHandler? editor}) {
    return CanvasRootState(
      parent: parent,
      item: this,
      editor: editor,
    );
  }
}

class CanvasRootState extends CanvasObjectState {
  CanvasRootState({
    super.parent,
    super.editor,
    required CanvasRoot super.item,
  });

  @override
  bool hitTestSelf(CanvasHitTestResult result, Offset position,
      {CanvasHitTestPredicate? test}) {
    return false;
  }

  @override
  bool selectTestSelf(
      CanvasHitTestResult result, Path path, TextDirection textDirection) {
    return false;
  }

  @override
  bool visitSnapAnchor(SnapAnchorVisitor visitor,
      {Matrix4? parentTransform, Matrix4? transform}) {
    for (var child in children) {
      if (!child.visitSnapAnchor(visitor, parentTransform: transform)) {
        return false;
      }
    }
    return true;
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

typedef CanvasHitTestPath = void Function(
    CanvasHitTestResult result, Path path);

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

  void addWithRawTransformPath({
    required Matrix4? transform,
    required Path path,
    required CanvasHitTestPath hitTest,
  }) {
    final Path transformedPath =
        transform == null ? path : path.transform(transform.storage);
    if (transform != null) {
      pushTransform(transform);
    }
    hitTest(this, transformedPath);
    if (transform != null) {
      popTransform();
    }
  }

  void addWithPaintTransformPath({
    required Matrix4? transform,
    required Path path,
    required CanvasHitTestPath hitTest,
  }) {
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return;
      }
    }
    addWithRawTransformPath(transform: transform, path: path, hitTest: hitTest);
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

class CanvasPathHitTestEntry extends HitTestEntry<CanvasItemState> {
  final PolygonOverlapResult overlap;

  CanvasPathHitTestEntry(super.target, this.overlap);

  @override
  String toString() {
    return 'CanvasPathHitTestEntry(target: $target, overlap: $overlap)';
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
