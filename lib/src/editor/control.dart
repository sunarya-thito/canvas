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

  @override
  String toString() {
    return 'EditorControlDelta(start: $start, end: $end)';
  }
}

class EditorResizeDelta {
  final Offset delta;
  final Alignment alignment;

  const EditorResizeDelta({
    required this.delta,
    required this.alignment,
  });

  EditorResizeDelta symmetric() {
    return EditorResizeDelta(
      delta: delta,
      alignment: Alignment.center,
    );
  }

  EditorResizeDelta proportional() {
    final dominant = delta.dx.abs() > delta.dy.abs() ? delta.dx : delta.dy;
    final proportionalDelta = Offset(
      dominant * delta.dx.sign,
      dominant * delta.dy.sign,
    );
    return EditorResizeDelta(
      delta: proportionalDelta,
      alignment: alignment,
    );
  }

  Offset get positionDelta {
    return Offset(
      -delta.dx * 0.5 * alignment.x,
      -delta.dy * 0.5 * alignment.y,
    );
  }

  Size get sizeDelta {
    return Size(
      delta.dx * alignment.x.abs() + (-delta.dx * 0.5 * alignment.x),
      delta.dy * alignment.y.abs() + (-delta.dy * 0.5 * alignment.y),
    );
  }
}

abstract class EditorControlSession {
  late EditorControlDelta _delta;
  void start(Offset start) {
    _delta = EditorControlDelta(start: start, end: start);
    onStart();
  }

  bool get shiftViewport => true;

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
  void onUpdateEditor(CanvasEditorHandler editor) {}

  void visitTransformedSnapAnchor(SnapAnchorVisitor visitor) {}
}

abstract class RulerSnappingControlSession extends EditorControlSession {
  CanvasSnapGuideline get snapAnchor;

  @override
  bool get shiftViewport => false;
}

class RulerCreateSnapAnchorControlSession extends RulerSnappingControlSession {
  final CanvasEditorHandler editor;
  final Axis direction;
  RulerCreateSnapAnchorControlSession(this.editor, this.direction);

  late CanvasSnapGuideline _snapAnchor;

  @override
  CanvasSnapGuideline get snapAnchor => _snapAnchor;

  @override
  void visitTransformedSnapAnchor(SnapAnchorVisitor visitor) {
    int index = 0;
    var list = editor.rulerGuidelines;
    visitor(CanvasRulerSnapAnchor(
        offset: snapAnchor.axis == Axis.horizontal ? delta.endY : delta.endX,
        direction: snapAnchor.axis,
        crossLineVisitor: () {
          while (index < list.length) {
            var line = list[index++];
            if (line.axis != snapAnchor.axis) {
              return line.offset;
            }
          }
          return null;
        }));
  }

  @override
  void onStart() {
    _snapAnchor = editor.createRulerSnapAnchor(
        direction == Axis.horizontal ? delta.startY : delta.startX, direction);
  }

  @override
  void onUpdate() {
    _snapAnchor.offset = direction == Axis.horizontal ? delta.endY : delta.endX;
  }

  @override
  void onApply() {
    if (!this.delta.hasChanged) {
      editor.removeRulerSnapAnchor(_snapAnchor);
      return;
    }
    double delta = snapAnchor.axis == Axis.horizontal
        ? this.delta.deltaY
        : this.delta.deltaX;
    if (delta < 1) {
      editor.removeRulerSnapAnchor(snapAnchor);
      return;
    }
    double offset = snapAnchor.offset * editor.transform.zoom +
        (snapAnchor.axis == Axis.horizontal
            ? (editor.viewportSize.height / 2 * editor.transform.zoom +
                editor.transform.offset.dy)
            : (editor.viewportSize.width / 2 * editor.transform.zoom +
                editor.transform.offset.dx));
    if (offset < 0 ||
        (snapAnchor.axis == Axis.horizontal &&
            offset > editor.viewportSize.height) ||
        (snapAnchor.axis == Axis.vertical &&
            offset > editor.viewportSize.width)) {
      editor.removeRulerSnapAnchor(snapAnchor);
      return;
    }
    editor.sendNotification(CanvasRulerSnapAnchorCreatedNotification(
        point: _snapAnchor, editor: editor));
  }

  @override
  void onCancel() {
    editor.removeRulerSnapAnchor(_snapAnchor);
  }
}

class RulerUpdateSnapAnchorControlSession extends RulerSnappingControlSession {
  final CanvasEditorHandler editor;
  @override
  final CanvasSnapGuideline snapAnchor;
  RulerUpdateSnapAnchorControlSession(this.editor, this.snapAnchor);

  @override
  void visitTransformedSnapAnchor(SnapAnchorVisitor visitor) {
    int index = 0;
    var list = editor.rulerGuidelines;
    visitor(CanvasRulerSnapAnchor(
      offset: snapAnchor.axis == Axis.horizontal ? delta.endY : delta.endX,
      direction: snapAnchor.axis,
      crossLineVisitor: snapAnchor.axis == Axis.horizontal
          ? () {
              while (index < list.length) {
                var line = list[index++];
                if (line.axis != snapAnchor.axis) {
                  return line.offset;
                }
              }
              return null;
            }
          : null,
    ));
  }

  @override
  void onUpdate() {
    snapAnchor.offset =
        snapAnchor.axis == Axis.horizontal ? delta.endY : delta.endX;
  }

  @override
  void onApply() {
    double offset = snapAnchor.offset * editor.transform.zoom +
        (snapAnchor.axis == Axis.horizontal
            ? (editor.viewportSize.height / 2 * editor.transform.zoom +
                editor.transform.offset.dy)
            : (editor.viewportSize.width / 2 * editor.transform.zoom +
                editor.transform.offset.dx));
    if (offset < 0 ||
        (snapAnchor.axis == Axis.horizontal &&
            offset > editor.viewportSize.height) ||
        (snapAnchor.axis == Axis.vertical &&
            offset > editor.viewportSize.width)) {
      editor.removeRulerSnapAnchor(snapAnchor);
      return;
    }
    editor.sendNotification(CanvasRulerSnapAnchorUpdatedNotification(
        editor: editor, point: snapAnchor));
  }

  @override
  void onCancel() {
    double delta = snapAnchor.axis == Axis.horizontal
        ? this.delta.deltaY
        : this.delta.deltaX;
    snapAnchor.offset -= delta;
  }
}

class SelectionMoveControlSession extends EditorControlSession {
  final Selection selection;
  final CanvasEditorHandler editor;

  SelectionMoveControlSession(this.selection, this.editor);

  @override
  void visitTransformedSnapAnchor(SnapAnchorVisitor visitor) {
    var offset = delta.delta;
    for (var group in selection.groups.value) {
      var box = group.getTransformControlBox();
      var transform = box.transform;
      var size = box.size;
      var topLeft = transformOffset(Offset.zero, transform) + offset;
      var topRight = transformOffset(Offset(size.width, 0), transform) + offset;
      var bottomLeft =
          transformOffset(Offset(0, size.height), transform) + offset;
      var bottomRight =
          transformOffset(Offset(size.width, size.height), transform) + offset;
      var center =
          transformOffset(Offset(size.width / 2, size.height / 2), transform) +
              offset;

      // top left
      if (!visitor(SelectionSnapAnchor(
        group: group,
        point: topLeft,
      ))) {
        return;
      }
      // top right
      if (!visitor(SelectionSnapAnchor(
        group: group,
        point: topRight,
      ))) {
        return;
      }
      // bottom left
      if (!visitor(SelectionSnapAnchor(
        group: group,
        point: bottomLeft,
      ))) {
        return;
      }
      // bottom right
      if (!visitor(SelectionSnapAnchor(
        group: group,
        point: bottomRight,
      ))) {
        return;
      }
      // center
      if (!visitor(SelectionSnapAnchor(
        group: group,
        point: center,
      ))) {
        return;
      }
    }
  }

  CanvasObjectState? _parentStart;
  CanvasObjectState? _parentEnd;
  bool _lockReparenting = false;
  bool _isReparenting = false;

  @override
  void onStart() {
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        item.editorOffset = Offset.zero; // this prevents snapping for the item
      }
    }
    if (editor.allowReparenting) {
      _startReparenting();
    }
  }

  @override
  void onUpdateEditor(CanvasEditorHandler editor) {
    if (editor.allowReparenting) {
      _startReparenting();
    } else {
      _stopReparenting();
    }
  }

  void _startReparenting() {
    if (_isReparenting) {
      return;
    }
    _isReparenting = true;
    _lockReparenting = false;
    CanvasItemState? targetHit = editor.findItemAtPosition(delta.start);
    while (targetHit != null) {
      if (targetHit is CanvasObjectState &&
          !selection.containsOrDescendant(targetHit)) {
        _parentStart = targetHit;
        break;
      }
      targetHit = targetHit.parent;
    }
  }

  void _stopReparenting() {
    if (!_isReparenting) {
      return;
    }
    _isReparenting = false;
    _parentEnd?.targetDrop.value = null;
    _parentEnd = null;
    _parentStart = null;
    _lockReparenting = false;
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        item.targetReparent = null;
      }
    }
  }

  @override
  void onUpdate() {
    selection.editorOffset.value = delta;
    CanvasObjectState? targetReparent;
    if (editor.allowReparenting) {
      CanvasItemState targetHit = editor.findItemAtPosition(delta.end);
      if (targetHit is CanvasObjectState &&
          (targetHit != _parentStart || _lockReparenting)) {
        targetReparent = targetHit;
      }
      _parentEnd?.targetDrop.value = null;
      _parentEnd = targetReparent;
      _parentEnd?.targetDrop.value = selection;
      if (_parentStart != targetHit &&
          targetHit is CanvasObjectState &&
          !_lockReparenting) {
        _lockReparenting = true;
      }
    }
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
    _resetEditorOffset();
  }

  @override
  void onCancel() {
    _resetEditorOffset();
  }

  void _resetEditorOffset() {
    selection.editorOffset.value = EditorControlDelta.zero;
    for (var group in selection.groups.value) {
      for (var item in group.selectedItems) {
        item.editorOffset = null;
      }
    }
    _stopReparenting();
  }
}

class _SelectionTransformSession {
  final CanvasItemState item;
  final CanvasLayoutData initialLayoutData;
  final Alignment? alignment; // null when the item is a singular selection

  _SelectionTransformSession({
    required this.item,
    required this.initialLayoutData,
    required this.alignment,
  });
}

class SelectionResizeControlSession extends EditorControlSession {
  final CanvasEditorHandler editor;
  final Selection selection;
  late List<_SelectionTransformSession> _sessions;

  SelectionResizeControlSession(
    this.editor,
    this.selection,
  );

  @override
  void onStart() {
    _sessions = [];
    var singularSelection = selection.singleSelection;
    if (singularSelection != null) {
      _sessions = [
        _SelectionTransformSession(
          item: singularSelection,
          initialLayoutData: singularSelection.item.layoutData,
          alignment: null,
        )
      ];
    } else {
      for (var group in selection.groups.value) {
        for (var item in group.selectedItems) {
          var layoutData = item.item.layoutData;
          var size = item.size;
          var transform = item.globalEditorTransform;
          // _sessions.add(_SelectionTransformSession(
          //   item: item,
          //   initialLayoutData: layoutData,
          //   alignment: item.getTransformControlAlignment(),
          // ));
        }
      }
    }
  }
}
