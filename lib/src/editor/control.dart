import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/notifications.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/cupertino.dart';

class EditorControlDelta {
  static EditorControlDelta zero =
      const EditorControlDelta(start: Offset.zero, end: Offset.zero);
  // the start and end must be at editor local coordinate (after translated and scaled by its transform)
  final Offset start;
  final Offset end;

  const EditorControlDelta({
    required this.start,
    required this.end,
  });

  EditorControlDelta copyWith({
    Offset? start,
    Offset? end,
  }) {
    return EditorControlDelta(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  EditorControlDelta shift(Offset delta) {
    return copyWith(
      end: end + delta,
    );
  }

  bool get hasChanged => start != end;

  Offset get delta => end - start;

  double get deltaY => end.dy - start.dy;
  double get deltaX => end.dx - start.dx;

  double get endX => end.dx;
  double get endY => end.dy;

  double get startX => start.dx;
  double get startY => start.dy;

  EditorControlDelta transform(Matrix4 transform) {
    return EditorControlDelta(
      start: transformOffset(start, transform),
      end: transformOffset(end, transform),
    );
  }
}

abstract class EditorControlSession {
  late EditorControlDelta _delta;
  void start(Offset start) {
    _delta = EditorControlDelta(start: start, end: start);
    onStart();
  }

  void update(Offset end) {
    _delta = _delta.copyWith(end: end);
    // onUpdate is called manually after the end is snapped
  }

  void shift(Offset delta) {
    _delta = _delta.shift(delta);
  }

  EditorControlDelta get delta => _delta;

  void onStart() {}
  void onUpdate() {}
  void onCancel() {}
  void onApply() {}

  void visitTransformedSnappingPoint(SnappingPointVisitor visitor) {}
}

abstract class RulerSnappingControlSession extends EditorControlSession {
  CanvasRulerSnappingPoint get snappingPoint;
}

class RulerCreateSnappingPointControlSession
    extends RulerSnappingControlSession {
  final CanvasEditorHandler editor;
  final Axis direction;
  RulerCreateSnappingPointControlSession(this.editor, this.direction);

  late CanvasRulerSnappingPoint _snappingPoint;

  @override
  CanvasRulerSnappingPoint get snappingPoint => _snappingPoint;

  @override
  void visitTransformedSnappingPoint(SnappingPointVisitor visitor) {
    visitor(CanvasRulerSnappingPoint(
      offset: direction == Axis.horizontal ? delta.startY : delta.startX,
      axis: direction,
    ));
  }

  @override
  void onStart() {
    _snappingPoint = editor.createRulerSnappingPoint(
        direction == Axis.horizontal ? delta.startY : delta.startX, direction);
  }

  @override
  void onUpdate() {
    _snappingPoint.offset =
        direction == Axis.horizontal ? delta.endY : delta.endX;
  }

  @override
  void onApply() {
    if (!this.delta.hasChanged) {
      editor.removeRulerSnappingPoint(_snappingPoint);
      return;
    }
    double delta = snappingPoint.axis == Axis.horizontal
        ? this.delta.deltaY
        : this.delta.deltaX;
    if (delta < 1) {
      editor.removeRulerSnappingPoint(snappingPoint);
      return;
    }
    double offset = snappingPoint.offset * editor.transform.zoom +
        (snappingPoint.axis == Axis.horizontal
            ? (editor.viewportSize.height / 2 * editor.transform.zoom +
                editor.transform.offset.dy)
            : (editor.viewportSize.width / 2 * editor.transform.zoom +
                editor.transform.offset.dx));
    if (offset < 0 ||
        (snappingPoint.axis == Axis.horizontal &&
            offset > editor.viewportSize.height) ||
        (snappingPoint.axis == Axis.vertical &&
            offset > editor.viewportSize.width)) {
      editor.removeRulerSnappingPoint(snappingPoint);
      return;
    }
    editor.sendNotification(CanvasRulerSnappingPointCreatedNotification(
        point: _snappingPoint, editor: editor));
  }

  @override
  void onCancel() {
    editor.removeRulerSnappingPoint(_snappingPoint);
  }
}

class RulerUpdateSnappingPointControlSession
    extends RulerSnappingControlSession {
  final CanvasEditorHandler editor;
  @override
  final CanvasRulerSnappingPoint snappingPoint;
  RulerUpdateSnappingPointControlSession(this.editor, this.snappingPoint);

  @override
  void onUpdate() {
    snappingPoint.offset =
        snappingPoint.axis == Axis.horizontal ? delta.endY : delta.endX;
  }

  @override
  void onApply() {
    double offset = snappingPoint.offset * editor.transform.zoom +
        (snappingPoint.axis == Axis.horizontal
            ? (editor.viewportSize.height / 2 * editor.transform.zoom +
                editor.transform.offset.dy)
            : (editor.viewportSize.width / 2 * editor.transform.zoom +
                editor.transform.offset.dx));
    if (offset < 0 ||
        (snappingPoint.axis == Axis.horizontal &&
            offset > editor.viewportSize.height) ||
        (snappingPoint.axis == Axis.vertical &&
            offset > editor.viewportSize.width)) {
      editor.removeRulerSnappingPoint(snappingPoint);
      return;
    }
    editor.sendNotification(CanvasRulerSnappingPointUpdatedNotification(
        editor: editor, point: snappingPoint));
  }

  @override
  void onCancel() {
    double delta = snappingPoint.axis == Axis.horizontal
        ? this.delta.deltaY
        : this.delta.deltaX;
    snappingPoint.offset -= delta;
  }
}

class SelectionMoveControlSession extends EditorControlSession {
  final Selection selection;
  final CanvasEditorHandler editor;

  SelectionMoveControlSession(this.selection, this.editor);

  @override
  void visitTransformedSnappingPoint(SnappingPointVisitor visitor) {
    // for (var group in selection.groups.value) {
    //   for (var item in group.selectedItems) {
    //     if (!item.visitSnappingPoint(
    //       (point) {
    //         return visitor(point.shift(delta.delta));
    //       },
    //       transform: item.globalTransform,
    //     )) {
    //       return;
    //     }
    //   }
    // }
  }

  CanvasObjectState? _parentStart;
  CanvasObjectState? _parentEnd;

  @override
  void onStart() {
    CanvasItemState? targetHit = editor.findItemAtPosition(delta.start);
    while (targetHit != null) {
      if (targetHit is CanvasObjectState &&
          !selection.containsOrDescendant(targetHit)) {
        _parentStart = targetHit;
        break;
      }
      targetHit = targetHit.parent;
    }
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        item.editorOffset = Offset.zero; // this prevents snapping for the item
      }
    }
    print('parentStart: $_parentStart');
  }

  @override
  void onUpdate() {
    CanvasItemState targetHit = editor.findItemAtPosition(delta.end);
    selection.editorOffset.value = delta;
    CanvasObjectState? targetReparent;
    if (targetHit is CanvasObjectState && targetHit != _parentStart) {
      targetReparent = targetHit;
    }
    _parentEnd?.targetDrop.value = null;
    _parentEnd = targetReparent;
    _parentEnd?.targetDrop.value = selection;
    print('target: $targetReparent');
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        var transform = Matrix4.inverted(item.globalTransform);
        var transformedDelta = delta.transform(transform);
        item.editorOffset = transformedDelta.delta;
        item.targetReparent = targetReparent;
      }
    }
  }

  @override
  void onApply() {
    print('apply');
    _resetEditorOffset();
  }

  @override
  void onCancel() {
    print('cancel');
    _resetEditorOffset();
  }

  void _resetEditorOffset() {
    _parentEnd?.targetDrop.value = null;
    selection.editorOffset.value = EditorControlDelta.zero;
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        item.editorOffset = null;
        item.targetReparent = null;
      }
    }
  }
}
