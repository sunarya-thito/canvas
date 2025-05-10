import 'package:canvas/canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class CanvasItem {
  CanvasLayoutData _layoutData;
  bool _locked;
  CanvasOverflow _overflow;

  final String? debugLabel;

  final List<CanvasItemState> _attachedStates = [];

  // TODO: There must be a better way to do this
  bool allowSnapping = true;

  CanvasItem({
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    bool locked = false,
    CanvasOverflow overflow = CanvasOverflow.none,
    this.debugLabel,
  })  : _layoutData = layoutData,
        _locked = locked,
        _overflow = overflow;

  set layoutData(CanvasLayoutData value) {
    if (_layoutData != value) {
      _layoutData = value;
      notifyStates();
    }
  }

  set locked(bool value) {
    if (_locked != value) {
      _locked = value;
      notifyStates();
    }
  }

  set overflow(CanvasOverflow value) {
    if (_overflow != value) {
      _overflow = value;
      notifyStates();
    }
  }

  CanvasLayoutData get layoutData => _layoutData;

  bool get locked => _locked;

  CanvasOverflow get overflow => _overflow;

  void notifyStates() {
    for (var state in attachedStates) {
      state.notify();
    }
  }

  void attach(covariant CanvasItemState state) {
    assert(!_attachedStates.contains(state),
        'State already attached to this item: $state');
    _attachedStates.add(state);
  }

  List<CanvasItemState> get attachedStates =>
      List.unmodifiable(_attachedStates);

  CanvasItemState createState({CanvasParentState? parent}) {
    return CanvasItemState(item: this, parent: parent);
  }

  void detach(CanvasItemState state) {
    assert(_attachedStates.contains(state),
        'State not attached to this item: $state');
    _attachedStates.remove(state);
  }

  @override
  String toString() {
    return 'CanvasItem($debugLabel)';
  }
}

class CanvasItemState with ChangeNotifier implements HitTestTarget {
  Size? _size;

  final CanvasItem item;

  final CanvasParentState? parent;

  CanvasParentData? _parentData;

  // CanvasItemEditorData _editorData = CanvasItemEditorData(
  //   dragOffset: null,
  //   reorderOffsetMap: const {},
  //   targetReorderIndex: null,
  //   targetReparent: null,
  // );

  Offset? _dragOffset;
  final Map<CanvasItemState, double> _reorderOffsetMap = const {};
  CanvasParentState? _targetReparent;
  int? _targetReorderIndex;

  bool _markedForDisposal = false;

  set unmountableParentData(CanvasParentData? value) {
    _parentData = value;
  }

  CanvasParentData? get unmountableParentData => _parentData;

  void markForDisposal() {
    _markedForDisposal = true;
  }

  void markForRebuild() {
    _markedForDisposal = false;
  }

  bool get markedForDisposal => _markedForDisposal;

  CanvasItemState({
    required this.item,
    required this.parent,
  });

  Path getPath() {
    return Path()..addRect(Offset.zero & size);
  }

  Widget render(BuildContext context, {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: renderContent(context),
    );
  }

  Widget renderEditor(BuildContext context, CanvasEditor editor,
      {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: CanvasItemEditorWidget(
        item: this,
        editor: editor,
        child: renderContent(context),
      ),
    );
  }

  Widget? renderContent(BuildContext context) => null;

  Rect computeBounds([Matrix4? parentTransform]) {
    List<Offset> points = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    if (parentTransform != null) {
      for (int i = 0; i < points.length; i++) {
        points[i] = transformOffset(points[i], parentTransform);
      }
    }
    double minX = points.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    double minY = points.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    double maxX = points.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
    double maxY = points.map((e) => e.dy).reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double computeMaxIntrinsicHeight(double width) {
    return 0;
  }

  double computeMaxIntrinsicWidth(double height) {
    return 0;
  }

  double computeMinIntrinsicHeight(double width) {
    return 0;
  }

  double computeMinIntrinsicWidth(double height) {
    return 0;
  }

  Matrix4 computeTransform({Matrix4? parentTransform}) {
    var transform = Matrix4.identity();
    transform.translate(parentData.position.dx, parentData.position.dy);
    transform.multiply(item.layoutData.transform);
    return parentTransform != null ? parentTransform * transform : transform;
  }

  Matrix4 computeEditorTransform({Matrix4? parentTransform}) {
    var transform = computeTransform(parentTransform: null);
    if (_dragOffset != null) {
      transform.translate(_dragOffset!.dx, _dragOffset!.dy);
    }
    return parentTransform != null ? parentTransform * transform : transform;
  }

  Matrix4 computeEditorGlobalTransform({Matrix4? parentTransform}) {
    var transform = computeEditorTransform(parentTransform: null);
    var parent = this.parent;
    while (parent != null) {
      transform =
          parent.computeEditorTransform(parentTransform: null) * transform;
      parent = parent.parent;
    }
    return parentTransform != null ? parentTransform * transform : transform;
  }

  Matrix4 computeGlobalTransform({Matrix4? parentTransform}) {
    var transform = computeTransform(parentTransform: null);
    var parent = this.parent;
    while (parent != null) {
      transform = parent.computeTransform(parentTransform: null) * transform;
      parent = parent.parent;
    }
    return parentTransform != null ? parentTransform * transform : transform;
  }

  Matrix4 computeEditorGlobalTransformUntil(CanvasParentState topParent) {
    var transform = computeEditorTransform(parentTransform: null);
    var parent = this.parent;
    while (parent != null && parent != topParent) {
      transform =
          parent.computeEditorTransform(parentTransform: null) * transform;
      parent = parent.parent;
    }
    return transform;
  }

  Rect computeGlobalBounds([Matrix4? parentTransform]) {
    List<Offset> points = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    Matrix4 transform =
        computeGlobalTransform(parentTransform: parentTransform);
    for (int i = 0; i < points.length; i++) {
      points[i] = transformOffset(points[i], transform);
    }
    double minX = points.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    double minY = points.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    double maxX = points.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
    double maxY = points.map((e) => e.dy).reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  CanvasParentState? findCommonParent(CanvasItemState other) {
    CanvasItemState? current = this;
    while (current != null) {
      CanvasItemState? otherCurrent = other;
      while (otherCurrent != null) {
        if (current == otherCurrent) {
          if (current is CanvasParentState) {
            return current;
          } else {
            return null;
          }
        }
        otherCurrent = otherCurrent.parent;
      }
      current = current.parent;
    }
    return null;
  }

  void forceLayout(Size size) {
    notifyListeners();
  }

  void notify() {
    relayout();
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    // unused
  }

  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (hitTestSelf(result, position)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    } else {
      return false;
    }
  }

  bool hitTestSelf(CanvasHitTestResult result, Offset position) {
    if (_dragOffset != null) {
      return false;
    }
    return size.containsIgnoreSign(position);
  }

  bool isDescendantOf(CanvasParentState parent) {
    CanvasItemState? current = this;
    while (current != null) {
      if (current == parent) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  void layout(Size size) {
    if (_size != size) {
      _size = size;
      print('performing layout on $this with size $size');
      forceLayout(size);
    }
  }

  CanvasParentData get parentData {
    assert(_parentData != null, 'Parent data is not set yet');
    return _parentData!;
  }

  void relayout() {
    if (_size != null) {
      if (parent != null) {
        parent!.relayout();
      } else {
        forceLayout(_size!);
      }
    }
  }

  void selectTest(CanvasHitTestResult result, Path path) {
    selectTestSelf(result, path);
  }

  void selectTestSelf(CanvasHitTestResult result, Path path) {
    Path self = getPath();
    Path combined = Path.combine(
      PathOperation.intersect,
      self,
      path,
    );
    Rect bounds = combined.getBounds();
    if (bounds.isEmpty) {
      return;
    }
    Rect testRect = self.getBounds();
    double boundsArea = testRect.width * testRect.height;
    double testArea = bounds.width * bounds.height;
    PathOverlap overlap;
    if (boundsArea > testArea) {
      overlap = PathOverlap.partial;
    } else {
      overlap = PathOverlap.full;
    }
    result.add(CanvasPathHitTestEntry(this, overlap));
  }

  Size get size {
    assert(_size != null, 'Size is not set yet');
    return _size!;
  }

  bool get parentHasEditorOffset {
    CanvasParentState? parent = this.parent;
    while (parent != null) {
      if (parent.dragOffset != null) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  bool visitGlobalSnapAnchor(SnapAnchorVisitor visitor,
      {Matrix4? parentTransform}) {
    var parent = this.parent;
    if (parent != null) {
      if (parentTransform == null) {
        parentTransform = parent.computeEditorGlobalTransform();
      } else {
        parentTransform =
            parentTransform * parent.computeEditorGlobalTransform();
      }
    }
    return visitSnapAnchor(visitor, parentTransform: parentTransform);
  }

  bool visitSnapAnchor(SnapAnchorVisitor visitor, {Matrix4? parentTransform}) {
    if (dragOffset != null || parentHasEditorOffset || !item.allowSnapping) {
      return true;
    }
    var transform = computeTransform(parentTransform: parentTransform);
    var size = this.size;
    Offset topLeft = transformOffset(Offset.zero, transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: topLeft))) {
      return false;
    }
    Offset topRight = transformOffset(Offset(size.width, 0), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: topRight))) {
      return false;
    }
    Offset bottomLeft = transformOffset(Offset(0, size.height), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: bottomLeft))) {
      return false;
    }
    Offset bottomRight =
        transformOffset(Offset(size.width, size.height), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: bottomRight))) {
      return false;
    }
    Offset center =
        transformOffset(Offset(size.width / 2, size.height / 2), transform);
    if (!visitor(CanvasItemSnapAnchor(item: this, point: center))) {
      return false;
    }
    return true;
  }

  void putReorderOffset(CanvasItemState child, double offset) {
    _reorderOffsetMap[child] = offset;
    notify();
  }

  void removeReorderOffset(CanvasItemState child) {
    _reorderOffsetMap.remove(child);
    notify();
  }

  void clearReorderOffsets() {
    notify();
  }

  Offset? get reorderOffsets {
    Map<CanvasItemState, double> reorderOffsetMap = _reorderOffsetMap;
    var parent = this.parent;
    if (parent is CanvasFrameState && reorderOffsetMap.isNotEmpty) {
      var parentLayout = parent.item.layout;
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
    }
    return null;
  }

  set targetReorderIndex(int? value) {
    if (_targetReorderIndex != value) {
      _targetReorderIndex = value;
      notifyListeners();
    }
  }

  int? get targetReorderIndex => _targetReorderIndex;

  CanvasParentState? get targetReparent => _targetReparent;

  set targetReparent(CanvasParentState? value) {
    if (_targetReparent != value) {
      _targetReparent = value;
      notifyListeners();
    }
  }

  set dragOffset(Offset? value) {
    if (_dragOffset != value) {
      _dragOffset = value;
      notifyListeners();
    }
  }

  Offset? get dragOffset => _dragOffset;

  @override
  String toString() {
    return 'CanvasItemState($item)';
  }
}
