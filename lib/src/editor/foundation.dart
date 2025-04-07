import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

enum CanvasSelectionMode {
  none,
  single,
  multiple,
}

typedef SnapAnchorHost = Function(SnapAnchorVisitor visitor);
typedef CanvasHitTestPredicate = bool Function(CanvasItemState item);
mixin CanvasEditorHandler {
  bool get allowReparenting;
  bool get symmetricResize;
  bool get proportionalResize;
  CanvasRootState get rootState;
  void sendNotification(Notification notification);
  EditorControlSession? get controlSession;
  T startControlSession<T extends EditorControlSession>(
      T session, Offset globalStart);
  T? updateControlSession<T extends EditorControlSession>(
      T session, Offset globalEnd);
  void endControlSession(EditorControlSession session);
  void cancelControlSession(EditorControlSession session);
  Ticker createTicker(TickerCallback onTick);
  EditorDragGestureSession? get activeMouseGesture;
  EditorDragGestureSession createMouseGesture();
  void stopMouseGesture(EditorDragGestureSession gesture);
  // returns the active selections and it is shared with other editors.
  List<Selection> get activeSelections;
  // avoid using this method for local selection, use localSelection instead.
  // this will use selectionClient as the key, so that the selection can be
  // updated instead of adding a new selection.
  void addSelection(Selection selection);
  void removeSelection(Selection selection);
  // local selection is the selection that is only available to the current
  // editor, it is not shared with other editors.
  Selection? get localSelection;
  set localSelection(Selection? selection);
  List<SelectionBox> get activeSelectionClients;
  void addSelectionRect(SelectionBox rect);
  void removeSelectionRect(SelectionBox rect);
  Selection? selectFromRect(SelectionBox rect, [Selection? currentSelection]);
  CanvasEditorTransform get transform;
  set transform(CanvasEditorTransform value);
  void addToLocalSelection(CanvasItemState item);
  void setToLocalSelection(CanvasItemState item);
  void removeFromLocalSelection(CanvasItemState item);
  bool isInLocalSelection(CanvasItemState item) {
    return localSelection?.contains(item) ?? false;
  }

  void hitTest(CanvasHitTestResult result, Offset position,
      {CanvasHitTestPredicate? test});
  void selectTest(CanvasHitTestResult result, Path path);
  // converts from widget local position to editor local position
  Offset globalToLocal(Offset position);
  Offset localToGlobal(Offset position);
  Matrix4 getLocalToGlobalTransform();
  Matrix4 getGlobalToLocalTransform();
  Size get viewportSize;
  Rect computeViewportBounds();
  void handleItemClick(CanvasItemState item);
  Selection? getSelectionForItem(CanvasItemState item);
  CanvasSnapGuideline createRulerSnapAnchor(double offset, Axis direction);
  void removeRulerSnapAnchor(CanvasSnapGuideline point);
  List<CanvasSnapGuideline> get rulerGuidelines;
  CanvasSnapGuideline? get selectedSnapAnchor =>
      selectedSnapAnchorListenable.value;
  set selectedSnapAnchor(CanvasSnapGuideline? point);
  ValueListenable<CanvasSnapGuideline?> get selectedSnapAnchorListenable;
  // SnappingResult? snap(SnapAnchor point);
  SnappingResult? snap(SnapAnchorHost host);

  SnappingConfiguration get snappingConfiguration;

  void dragViewport(Offset delta);
  void zoomAtViewport(Offset at, double delta);

  // position is in editor local coordinates
  CanvasItemState findItemAtPosition(Offset position,
      {CanvasHitTestPredicate? test}) {
    CanvasHitTestResult result = CanvasHitTestResult();
    hitTest(result, position, test: test);
    if (result.path.isNotEmpty) {
      return result.path.first.target;
    }
    return rootState;
  }

  bool visitSnapAnchor(SnapAnchorVisitor visitor);
}

class CanvasEditorTransform {
  final Offset offset;
  final double zoom;

  const CanvasEditorTransform({
    this.offset = Offset.zero,
    this.zoom = 1.0,
  });

  CanvasEditorTransform copyWith({
    Offset? offset,
    double? zoom,
  }) {
    return CanvasEditorTransform(
      offset: offset ?? this.offset,
      zoom: zoom ?? this.zoom,
    );
  }

  CanvasEditorTransform drag(Offset delta) {
    return copyWith(offset: offset + delta);
  }

  CanvasEditorTransform zoomAt(Offset position,
      {double delta = 0.1, double? maxZoom, double? minZoom}) {
    delta = delta * zoom;
    var currentZoom = zoom;
    if (maxZoom != null) {
      if (currentZoom + delta > maxZoom) {
        delta = maxZoom - currentZoom;
      }
    }
    if (minZoom != null) {
      if (currentZoom + delta < minZoom) {
        delta = minZoom - currentZoom;
      }
    }
    return copyWith(
      offset: offset - (position - offset) * delta / zoom,
      zoom: zoom + delta,
    );
  }

  @override
  String toString() {
    return 'CanvasEditorTransform{offset: $offset, zoom: $zoom}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasEditorTransform &&
        other.offset == offset &&
        other.zoom == zoom;
  }

  @override
  int get hashCode {
    return Object.hash(offset, zoom);
  }
}

class CanvasEditorController extends ValueNotifier<CanvasEditorTransform> {
  CanvasEditorController({
    CanvasEditorTransform? value,
  }) : super(value ?? const CanvasEditorTransform());
}
