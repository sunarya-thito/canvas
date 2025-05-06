import 'package:canvas/canvas.dart';
import 'package:canvas/src/collections.dart';
import 'package:canvas/src/editor/grid/grid.dart';
import 'package:canvas/src/editor/snap/item.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:canvas/src/item/widget/base.dart';
import 'package:canvas/src/layout/fixed.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BaseCanvasItem extends CanvasItem {
  CanvasLayoutData _layoutData;
  bool _locked;
  CanvasOverflow _overflow;

  @override
  final String? debugLabel;

  final List<BaseCanvasItemState> _attachedStates = [];

  BaseCanvasItem({
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    bool locked = false,
    CanvasOverflow overflow = CanvasOverflow.none,
    this.debugLabel,
  })  : _layoutData = layoutData,
        _locked = locked,
        _overflow = overflow;

  @override
  set layoutData(CanvasLayoutData value) {
    if (_layoutData != value) {
      _layoutData = value;
      notifyStates();
    }
  }

  @override
  set locked(bool value) {
    if (_locked != value) {
      _locked = value;
      notifyStates();
    }
  }

  @override
  set overflow(CanvasOverflow value) {
    if (_overflow != value) {
      _overflow = value;
      notifyStates();
    }
  }

  @override
  CanvasLayoutData get layoutData => _layoutData;

  @override
  bool get locked => _locked;

  @override
  CanvasOverflow get overflow => _overflow;

  void notifyStates() {
    for (var state in attachedStates) {
      state.notify();
    }
  }

  @override
  void attach(covariant BaseCanvasItemState state) {
    assert(!_attachedStates.contains(state),
        'State already attached to this item: $state');
    _attachedStates.add(state);
  }

  @override
  List<BaseCanvasItemState> get attachedStates =>
      List.unmodifiable(_attachedStates);

  @override
  BaseCanvasItemState createState({CanvasParentState? parent}) {
    return BaseCanvasItemState(item: this, parent: parent);
  }

  @override
  void detach(CanvasItemState state) {
    assert(_attachedStates.contains(state),
        'State not attached to this item: $state');
    _attachedStates.remove(state);
  }
}

class BaseCanvasItemState extends CanvasItemState with ChangeNotifier {
  Size? _size;

  @override
  final CanvasItem item;

  @override
  final CanvasParentState? parent;

  CanvasParentData? _parentData;

  CanvasItemEditorData _editorData = CanvasItemEditorData(
    dragOffset: null,
    reorderOffsetMap: const {},
    targetReorderIndex: null,
    targetReparent: null,
  );

  bool _markedForDisposal = false;

  @override
  set unmountableParentData(CanvasParentData? value) {
    _parentData = value;
  }

  @override
  CanvasParentData? get unmountableParentData => _parentData;

  @override
  void markForDisposal() {
    _markedForDisposal = true;
  }

  @override
  void markForRebuild() {
    _markedForDisposal = false;
  }

  @override
  bool get markedForDisposal => _markedForDisposal;

  BaseCanvasItemState({
    required this.item,
    required this.parent,
  });

  @override
  set editorData(CanvasItemEditorData value) {
    if (_editorData != value) {
      _editorData = value;
      notify();
    }
  }

  @override
  CanvasItemEditorData get editorData => _editorData;

  @override
  Path getPath() {
    return Path()..addRect(Offset.zero & size);
  }

  @override
  Widget render(BuildContext context, {Matrix4? transform}) {
    return CanvasItemWidget(
      key: ValueKey(this),
      item: this,
      transform: transform,
      child: renderContent(context),
    );
  }

  @override
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

  @override
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

  @override
  double computeMaxIntrinsicHeight(double width) {
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return 0;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return 0;
  }

  @override
  Matrix4 computeTransform({Matrix4? parentTransform}) {
    var transform = Matrix4.identity();
    transform.translate(parentData.position.dx, parentData.position.dy);
    transform.multiply(item.layoutData.transform);
    return parentTransform != null ? parentTransform * transform : transform;
  }

  @override
  Matrix4 computeEditorTransform({Matrix4? parentTransform}) {
    var transform = computeTransform(parentTransform: null);
    if (editorData.dragOffset != null) {
      transform.translate(editorData.dragOffset!.dx, editorData.dragOffset!.dy);
    }
    return parentTransform != null ? parentTransform * transform : transform;
  }

  @override
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

  @override
  Matrix4 computeGlobalTransform({Matrix4? parentTransform}) {
    var transform = computeTransform(parentTransform: null);
    var parent = this.parent;
    while (parent != null) {
      transform = parent.computeTransform(parentTransform: null) * transform;
      parent = parent.parent;
    }
    return parentTransform != null ? parentTransform * transform : transform;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  bool hitTest(CanvasHitTestResult result, Offset position) {
    if (hitTestSelf(result, position)) {
      result.add(CanvasHitTestEntry(this, position));
      return true;
    } else {
      return false;
    }
  }

  @override
  bool hitTestSelf(CanvasHitTestResult result, Offset position) {
    if (editorData.dragOffset != null) {
      return false;
    }
    return size.containsIgnoreSign(position);
  }

  @override
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

  @override
  void layout(Size size) {
    if (_size != size) {
      _size = size;
      forceLayout(size);
    }
  }

  @override
  CanvasParentData get parentData {
    assert(_parentData != null, 'Parent data is not set yet');
    return _parentData!;
  }

  @override
  void relayout() {
    if (_size != null) {
      forceLayout(_size!);
    }
  }

  @override
  void selectTest(CanvasHitTestResult result, Path path) {
    selectTestSelf(result, path);
  }

  @override
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
    if (boundsArea < testArea) {
      overlap = PathOverlap.partial;
    } else {
      overlap = PathOverlap.full;
    }
    result.add(CanvasPathHitTestEntry(this, overlap));
  }

  @override
  Size get size {
    assert(_size != null, 'Size is not set yet');
    return _size!;
  }

  bool get parentHasEditorOffset {
    CanvasParentState? parent = this.parent;
    while (parent != null) {
      if (parent.editorData.dragOffset != null) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  @override
  bool visitSnapAnchor(SnapAnchorVisitor visitor, {Matrix4? parentTransform}) {
    if (editorData.dragOffset != null ||
        parentHasEditorOffset ||
        !item.allowSnapping) {
      return false;
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

  @override
  void putReorderOffset(CanvasItemState child, double offset) {
    Map<CanvasItemState, double> reorderOffsetMap = Map.of(
      editorData.reorderOffsetMap,
    );
    reorderOffsetMap[child] = offset;
    editorData = CanvasItemEditorData(
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
    editorData = CanvasItemEditorData(
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  void clearReorderOffsets() {
    editorData = CanvasItemEditorData(
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
    editorData = CanvasItemEditorData(
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
    editorData = CanvasItemEditorData(
      dragOffset: editorData.dragOffset,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: value,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  set dragOffset(Offset? value) {
    editorData = CanvasItemEditorData(
      dragOffset: value,
      reorderOffsetMap: editorData.reorderOffsetMap,
      targetReparent: editorData.targetReparent,
      targetReorderIndex: editorData.targetReorderIndex,
    );
  }

  @override
  Offset? get dragOffset => editorData.dragOffset;
}
