import 'dart:async';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control/control.dart';
import 'package:canvas/src/editor/gestures.dart';
import 'package:canvas/src/editor/gestures/selection.dart';
import 'package:canvas/src/editor/ruler/ruler.dart';
import 'package:canvas/src/editor/snap/absolute.dart';
import 'package:canvas/src/editor/snap/ruler.dart';
import 'package:canvas/src/item.dart';
import 'package:canvas/src/item/path.dart';
import 'package:flutter/cupertino.dart';

import 'selection/box.dart';
import 'selection/client.dart';
import 'selection/selection.dart';
import 'snap/snap.dart';

enum CanvasSelectionMode {
  none,
  single,
  multiple,
}

class CanvasEditor with ChangeNotifier {
  bool _allowReparenting;
  bool _symmetricResize;
  bool _proportionalResize;
  late CanvasItemState _rootState;
  EditorGesture _gesture;
  CanvasSelectionMode _selectionMode;
  Offset _offset;
  double _zoom;
  EditorGestureSession? _gestureSession;
  EditorControlSession? _controlSession;
  SnappingConfiguration _snappingConfiguration;
  final StreamController<CanvasEvent> _eventController =
      StreamController<CanvasEvent>.broadcast();
  final List<Selection> _selections = [];
  final List<SelectionBox> _selectionBoxes = [];
  final List<CanvasSnapGuideline> _rulerSnapAnchors = [];
  CanvasSnapGuideline? _selectedSnapGuideline;
  SnappingResult? _snappingResult;

  Offset _shift = Offset.zero;

  CanvasEditor({
    required CanvasItem root,
    CanvasSelectionMode selectionMode = CanvasSelectionMode.single,
    bool allowReparenting = true,
    bool symmetricResize = false,
    bool proportionalResize = false,
    double zoom = 1.0,
    Offset offset = Offset.zero,
  })  : _selectionMode = selectionMode,
        _allowReparenting = allowReparenting,
        _symmetricResize = symmetricResize,
        _proportionalResize = proportionalResize,
        _zoom = zoom,
        _offset = offset,
        _gesture = EditorSelectDragGesture(),
        _snappingConfiguration = SnappingConfiguration() {
    _rootState = root.createState();
    root.attach(_rootState);
    _rootState.layout(Size.zero);
  }

  SnappingResult? get snappingResult => _snappingResult;
  set snappingResult(SnappingResult? value) {
    if (_snappingResult != value) {
      _snappingResult = value;
      notifyListeners();
    }
  }

  CanvasItem get root => _rootState.item;
  set root(CanvasItem value) {
    if (_rootState.item != value) {
      _rootState.item.detach(_rootState);
      _rootState.dispose();
      _rootState = value.createState();
      value.attach(_rootState);
      notifyListeners();
    }
  }

  void handleCursorPosition(Offset position, Size size) {
    if (_controlSession?.shiftViewport != true) {
      _shift = Offset.zero;
      return;
    }
    // position is at editor widget level
    double shiftX = 0;
    double shiftY = 0;
    const shiftPadding = EdgeInsets.all(20);

    double verticalMin = shiftPadding.top;
    double verticalMax = size.height - shiftPadding.bottom;
    double horizontalMin = shiftPadding.left;
    double horizontalMax = size.width - shiftPadding.right;

    if (position.dy < verticalMin) {
      shiftY = -(verticalMin - position.dy) / shiftPadding.top;
    } else {
      shiftY = (position.dy - verticalMax) / shiftPadding.bottom;
    }

    if (position.dx < horizontalMin) {
      shiftX = -(horizontalMin - position.dx) / shiftPadding.left;
    } else {
      shiftX = (position.dx - horizontalMax) / shiftPadding.right;
    }
    _shift = Offset(shiftX, shiftY);
  }

  void tick(Duration delta) {
    var offset = Offset(_shift.dx * delta.inMilliseconds / 2,
        _shift.dy * delta.inMilliseconds / 2);
    if (offset != Offset.zero) {
      _offset += offset;
      notifyListeners();
    }
  }

  bool get allowReparenting => _allowReparenting;
  set allowReparenting(bool value) {
    if (_allowReparenting != value) {
      _allowReparenting = value;
      notifyListeners();
    }
  }

  bool get symmetricResize => _symmetricResize;
  set symmetricResize(bool value) {
    if (_symmetricResize != value) {
      _symmetricResize = value;
      notifyListeners();
    }
  }

  bool get proportionalResize => _proportionalResize;
  set proportionalResize(bool value) {
    if (_proportionalResize != value) {
      _proportionalResize = value;
      notifyListeners();
    }
  }

  CanvasItemState get rootState => _rootState;
  EditorControlSession? get controlSession => _controlSession;
  CanvasItemState? findItemAt(Offset position,
      {bool Function(CanvasItemState)? filter}) {
    CanvasHitTestResult result = CanvasHitTestResult();
    hitTest(result, position);
    for (var entry in result.path) {
      var item = entry.target;
      if (filter == null || filter(item)) {
        return item;
      }
    }
    return null;
  }

  void startControlSession(
      EditorControlSession session, Offset localPosition, Size viewportSize) {
    localPosition = viewportGlobalToLocal(this, viewportSize, localPosition);
    cancelControlSession();
    _controlSession = session;
    _controlSession!.handleStartSession(this, viewportSize);
    _controlSession!.handleDragStart(localPosition, viewportSize);
  }

  void updateControlSession(Offset localPosition, Size viewportSize) {
    localPosition = viewportGlobalToLocal(this, viewportSize, localPosition);
    _controlSession?.handleDragUpdate(localPosition, viewportSize);
    if (snappingConfiguration.enableSnapping) {
      var snapResult = snap(_controlSession!.visitSnapAnchor);
      snappingResult = snapResult;
      if (snapResult != null) {
        localPosition -= snapResult.snapDelta;
      }
    }
    _controlSession?.handleDragUpdate(localPosition, viewportSize);
    _controlSession?.onDragUpdate();
  }

  void endControlSession() {
    _controlSession?.handleDragEnd();
    _controlSession = null;
    snappingResult = null;
  }

  void cancelControlSession() {
    _controlSession?.handleDragCancel();
    _controlSession = null;
    snappingResult = null;
  }

  EditorGesture get gesture => _gesture;
  set gesture(EditorGesture value) {
    if (_gesture != value) {
      _gesture = value;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    _controlSession?.handleEditorUpdate();
    super.notifyListeners();
  }

  EditorGestureSession? get gestureSession => _gestureSession;
  void startGestureSession(Offset localPosition, Size viewportSize) {
    localPosition = viewportGlobalToLocal(this, viewportSize, localPosition);
    cancelGestureSession();
    _gestureSession = gesture.createSession(this);
    _gestureSession!.handleDragStart(localPosition, viewportSize);
  }

  void updateGestureSession(Offset localPosition, Size viewportSize) {
    localPosition = viewportGlobalToLocal(this, viewportSize, localPosition);
    if (!gesture.interceptPointerEvents &&
        snappingConfiguration.enableSnapping &&
        gesture.allowSnapping) {
      var snapResult = snap((visitor) {
        return visitor(AbsoluteSnapAnchor(point: localPosition));
      });
      snappingResult = snapResult;
      if (snapResult != null) {
        localPosition -= snapResult.snapDelta;
      }
    }
    _gestureSession?.handleDragUpdate(localPosition, viewportSize);
  }

  void endGestureSession() {
    _gestureSession?.handleDragEnd();
    _gestureSession = null;
    _snappingResult = null;
  }

  void cancelGestureSession() {
    _gestureSession?.handleDragCancel();
    _gestureSession = null;
    _snappingResult = null;
  }

  List<Selection> get selections => List.unmodifiable(_selections);
  Selection? getSelection(SelectionClient client) {
    for (var selection in _selections) {
      if (selection.client == client) {
        return selection;
      }
    }
    return null;
  }

  void addSelection(Selection selection) {
    removeSelection(selection.client);
    _selections.add(selection);
    notifyListeners();
  }

  void removeSelection(SelectionClient selection) {
    _selections.removeWhere((s) => s.client == selection);
    notifyListeners();
  }

  Selection? get localSelection {
    for (var selection in _selections) {
      if (selection.client == SelectionClient.local) {
        return selection;
      }
    }
    return null;
  }

  set localSelection(Selection? selection) {
    if (selection != null) {
      _selectedSnapGuideline = null;
    }
    removeSelection(SelectionClient.local);
    if (selection != null) {
      addSelection(selection);
    }
    dispatchEvent(CanvasLocalSelectionChangedNotification(
        editor: this, selection: selection));
  }

  void addToLocalSelection(CanvasItemState item) {
    Selection? local = localSelection;
    if (local == null) {
      local = Selection.fromSelection([item], client: SelectionClient.local);
      addSelection(local);
    } else {
      local = local.addSelection(item);
      addSelection(local);
    }
  }

  void setToLocalSelection(CanvasItemState item) {
    localSelection =
        Selection.fromSelection([item], client: SelectionClient.local);
  }

  List<SelectionBox> get activeSelectionClients =>
      List.unmodifiable(_selectionBoxes);
  void addSelectionRect(SelectionBox rect) {
    _selectionBoxes.add(rect);
    notifyListeners();
  }

  void removeSelectionRect(SelectionBox rect) {
    _selectionBoxes.remove(rect);
    notifyListeners();
  }

  Selection? selectFromRect(SelectionBox rect, [Selection? currentSelection]) {
    if (rect.rect.isEmpty) {
      return null;
    }
    Path path = Path()..addRect(rect.rect);
    CanvasHitTestResult result = CanvasHitTestResult();
    selectTest(result, path);

    PathOverlap findHitTestResult(CanvasItemState item) {
      for (var entry in result.path) {
        if (entry.target == item && entry is CanvasPathHitTestEntry) {
          return entry.overlap;
        }
      }
      return PathOverlap.none;
    }

    List<CanvasItemState> selected = [];

    for (var entry in result.path) {
      if (entry is CanvasPathHitTestEntry) {
        var item = entry.target;
        if (item.item.locked) {
          continue;
        }
        bool hasAnyOverlapChildren = item is CanvasParentState &&
            item.children.any((child) {
              return findHitTestResult(child) != PathOverlap.none;
            });
        if ((hasAnyOverlapChildren && entry.overlap == PathOverlap.full) ||
            (!hasAnyOverlapChildren && entry.overlap == PathOverlap.partial)) {
          selected.add(item);
        }
      }
    }

    if (selectionMode == CanvasSelectionMode.single) {
      if (selected.isEmpty) {
        localSelection = null;
      } else {
        localSelection = Selection.fromSelection(selected);
      }
    } else {
      if (selected.isEmpty) {
        localSelection = currentSelection;
        return currentSelection;
      }
      currentSelection ??= Selection(groups: [], client: SelectionClient.local);
      for (var item in selected) {
        var alreadySelected = currentSelection?.items.contains(item);
        if (alreadySelected == false) {
          currentSelection = currentSelection?.addSelection(item);
        } else {
          currentSelection = currentSelection?.removeSelection(item);
        }
      }
      localSelection =
          currentSelection == null || currentSelection.items.isEmpty
              ? null
              : currentSelection;
      return currentSelection;
    }
    return null;
  }

  CanvasSelectionMode get selectionMode => _selectionMode;
  set selectionMode(CanvasSelectionMode value) {
    _selectionMode = value;
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset != value) {
      _offset = value;
      notifyListeners();
    }
  }

  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom != value) {
      _zoom = value;
      notifyListeners();
    }
  }

  void handleItemClick(CanvasItemState item) {
    if (item == _rootState) {
      if (selectionMode != CanvasSelectionMode.multiple) {
        localSelection = null;
      }
      return;
    }
    if (selectionMode != CanvasSelectionMode.multiple) {
      localSelection = null;
    }
    switch (selectionMode) {
      case CanvasSelectionMode.single:
        setToLocalSelection(item);
        break;
      case CanvasSelectionMode.multiple:
        if (isInLocalSelection(item)) {
          removeFromLocalSelection(item);
        } else {
          addToLocalSelection(item);
        }
        break;
      case CanvasSelectionMode.none:
        break;
    }
  }

  void removeFromLocalSelection(CanvasItemState item) {
    if (localSelection == null) {
      return;
    }
    localSelection = localSelection!.removeSelection(item);
  }

  bool isInLocalSelection(CanvasItemState item) {
    if (localSelection == null) {
      return false;
    }
    return localSelection!.items.contains(item);
  }

  void disposeObject(CanvasItemState item) {
    var parent = item.parent;
    for (var i = _selections.length - 1; i >= 0; i--) {
      var selection = _selections[i];
      var newSelection = selection.removeSelection(item);
      if (newSelection.isEmpty) {
        _selections.removeAt(i);
      } else {
        _selections[i] = newSelection;
      }
    }
    parent?.item.removeChild(item.item);
    notifyListeners();
    dispatchEvent(CanvasItemsDeletedNotification(
      editor: this,
      items: [item],
    ));
  }

  void disposeObjects(List<CanvasItemState> items) {
    for (var item in items) {
      var parent = item.parent;
      for (var i = _selections.length - 1; i >= 0; i--) {
        var selection = _selections[i];
        var newSelection = selection.removeSelection(item);
        if (newSelection.isEmpty) {
          _selections.removeAt(i);
        } else {
          _selections[i] = newSelection;
        }
      }
      parent?.item.removeChild(item.item);
    }
    notifyListeners();
    dispatchEvent(CanvasItemsDeletedNotification(
      editor: this,
      items: items,
    ));
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    rootState.hitTest(result, position);
  }

  void selectTest(CanvasHitTestResult result, Path path) {
    rootState.selectTest(result, path);
  }

  Matrix4 computeTransform(Size viewportSize) {
    Matrix4 transform = Matrix4.identity();
    transform.translate(offset.dx, offset.dy);
    transform.scale(zoom, zoom, 1.0);
    transform.translate(viewportSize.width / 2, viewportSize.height / 2);
    return transform;
  }

  Rect computeBounds(Size viewportSize) {
    Matrix4 transform = computeTransform(viewportSize);
    return rootState.computeGlobalBounds(transform);
  }

  CanvasSnapGuideline createRulerSnapAnchor(double offset, Axis direction) {
    CanvasSnapGuideline anchor =
        CanvasSnapGuideline(offset: offset, axis: direction);
    _rulerSnapAnchors.add(anchor);
    notifyListeners();
    return anchor;
  }

  void removeRulerSnapAnchor(CanvasSnapGuideline anchor) {
    if (_rulerSnapAnchors.remove(anchor)) {
      notifyListeners();
      dispatchEvent(CanvasRulerSnapGuidelineDeletedNotification(
        editor: this,
        guideline: anchor,
      ));
    }
  }

  List<CanvasSnapGuideline> get rulerSnapAnchors =>
      List.unmodifiable(_rulerSnapAnchors);
  CanvasSnapGuideline? get selectedSnapGuideline => _selectedSnapGuideline;
  set selectedSnapGuideline(CanvasSnapGuideline? value) {
    if (_selectedSnapGuideline != value) {
      localSelection = null;
      _selectedSnapGuideline = value;
      notifyListeners();
    }
  }

  SnappingResult? snap(SnapAnchorHost host) {
    if (!snappingConfiguration.enableSnapping) {
      return null;
    }
    List<SnappingEntry> candidates = [];
    host((point) {
      visitSnapAnchor((other) {
        if (!point.canSnapInto(other)) {
          return true;
        }
        point.visitLines((line) {
          other.visitLines((otherLine) {
            double distance = line.distanceTo(otherLine);
            if (distance < snappingConfiguration.snappingDistance) {
              candidates.add(
                SnappingEntry(
                    distance: distance,
                    snapDelta: line.snapToLine(otherLine),
                    sourceLine: line,
                    targetLine: otherLine,
                    sourceAnchor: point,
                    targetAnchor: other),
              );
            }
            return true;
          });
          return true;
        });
        return true;
      });
      return true;
    });

    double minHorizontalDistance = double.infinity;
    double minVerticalDistance = double.infinity;
    double horizontalSnap = 0;
    double verticalSnap = 0;
    for (var entry in candidates) {
      if (entry.sourceLine.direction == Axis.horizontal) {
        if (entry.distance < minHorizontalDistance) {
          minHorizontalDistance = entry.distance;
          horizontalSnap = entry.snapDelta.dy;
        }
      } else if (entry.sourceLine.direction == Axis.vertical) {
        if (entry.distance < minVerticalDistance) {
          minVerticalDistance = entry.distance;
          verticalSnap = entry.snapDelta.dx;
        }
      }
    }
    Offset delta = Offset(verticalSnap, horizontalSnap);
    if (delta == Offset.zero) {
      return null;
    }
    List<SnappingEntry> entries = candidates
        .where((entry) => entry.sourceLine.direction == Axis.horizontal
            ? entry.snapDelta.dy == horizontalSnap
            : entry.snapDelta.dx == verticalSnap)
        .toList();
    return SnappingResult(
      snapDelta: delta,
      entries: entries,
    );
  }

  SnappingConfiguration get snappingConfiguration => _snappingConfiguration;
  set snappingConfiguration(SnappingConfiguration value) {
    _snappingConfiguration = value;
  }

  void dragViewport(Offset delta) {
    if (delta == Offset.zero) {
      return;
    }
    offset = Offset(offset.dx + delta.dx, offset.dy + delta.dy);
    notifyListeners();
  }

  void zoomViewport(double delta, Size viewportSize, {Offset? focalPoint}) {
    if (delta == 0) {
      return;
    }
    focalPoint ??= Offset(viewportSize.width / 2, viewportSize.height / 2);
    delta = delta * zoom;
    _offset = offset - (focalPoint - offset) * delta / zoom;
    _zoom += delta;
    notifyListeners();
  }

  void resetViewport() {
    if (offset == Offset.zero && zoom == 1.0) {
      return;
    }
    offset = Offset.zero;
    zoom = 1.0;
    notifyListeners();
  }

  void fitToViewport(Size viewportSize) {
    Rect bounds = computeBounds(viewportSize);
    if (bounds.isEmpty) {
      return;
    }
    double width = viewportSize.width;
    double height = viewportSize.height;
    double scaleX = width / bounds.width;
    double scaleY = height / bounds.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    Offset center = Offset(
      bounds.left + bounds.width / 2,
      bounds.top + bounds.height / 2,
    );
    offset = center - (viewportSize.center(Offset.zero) * scale);
    zoom = scale;
    notifyListeners();
  }

  bool visitSnapAnchor(SnapAnchorVisitor visitor) {
    for (var rulerSnapAnchor in _rulerSnapAnchors) {
      if (!visitor(CanvasRulerSnapAnchor(
          offset: rulerSnapAnchor.offset, direction: rulerSnapAnchor.axis))) {
        return false;
      }
    }
    return rootState.visitSnapAnchor(visitor);
  }

  Stream<CanvasEvent> get events => _eventController.stream;
  void dispatchEvent(CanvasEvent event) {
    _eventController.add(event);
  }

  StreamSubscription<CanvasEvent> listen(
      void Function(CanvasEvent event) onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) {
    return _eventController.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void selectAll() {
    if (rootState is CanvasParentState) {
      var parent = rootState as CanvasParentState;
      localSelection = Selection.fromSelection(
        parent.children.where((child) => !child.item.locked).toList(),
        client: SelectionClient.local,
      );
    } else {
      localSelection = null;
    }
  }
}
