import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/notifications.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:flutter/cupertino.dart';

class EditorControlDelta {
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

  Offset get delta => end - start;

  EditorControlDelta transform(Matrix4 transform) {
    return EditorControlDelta(
      start: transformOffset(start, transform),
      end: transformOffset(end, transform),
    );
  }
}

abstract class EditorControlSession {
  const EditorControlSession();
  void start(Offset start);
  void update(Offset end);
  void cancel();
  void apply();
  CanvasRulerSnappingPoint computeNewSnappingPoint(Offset end);
}

abstract class RulerSnappingControlSession extends EditorControlSession {
  CanvasRulerSnappingPoint get snappingPoint;
}

class RulerCreateSnappingPointControlSession
    extends RulerSnappingControlSession {
  final CanvasEditorHandler editor;
  final Axis direction;
  RulerCreateSnappingPointControlSession(this.editor, this.direction);

  late Offset _startOffset;
  Offset? _end;
  late CanvasRulerSnappingPoint _snappingPoint;

  @override
  CanvasRulerSnappingPoint get snappingPoint => _snappingPoint;

  @override
  CanvasRulerSnappingPoint computeNewSnappingPoint(Offset end) {
    return CanvasRulerSnappingPoint(
      offset: direction == Axis.horizontal ? end.dy : end.dx,
      axis: direction,
    );
  }

  @override
  void start(Offset start) {
    _startOffset = start;
    _snappingPoint = editor.createRulerSnappingPoint(
        direction == Axis.horizontal ? start.dy : start.dx, direction);
  }

  @override
  void update(Offset end) {
    _snappingPoint.offset = direction == Axis.horizontal ? end.dy : end.dx;
    _end = end;
  }

  @override
  void apply() {
    if (_end == null) {
      editor.removeRulerSnappingPoint(_snappingPoint);
      return;
    }
    double delta = snappingPoint.axis == Axis.horizontal
        ? _end!.dy - _startOffset.dy
        : _end!.dx - _startOffset.dx;
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
  void cancel() {
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
  CanvasRulerSnappingPoint computeNewSnappingPoint(Offset end) {
    return CanvasRulerSnappingPoint(
      offset: snappingPoint.axis == Axis.horizontal ? end.dy : end.dx,
      axis: snappingPoint.axis,
    );
  }

  late Offset _start;
  Offset? _end;
  @override
  void start(Offset start) {
    _start = start;
  }

  @override
  void update(Offset end) {
    _end = end;
    snappingPoint.offset =
        snappingPoint.axis == Axis.horizontal ? end.dy : end.dx;
  }

  @override
  void apply() {
    if (_end == null) {
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
    editor.sendNotification(CanvasRulerSnappingPointUpdatedNotification(
        editor: editor, point: snappingPoint));
  }

  @override
  void cancel() {
    if (_end == null) {
      return;
    }
    double delta = snappingPoint.axis == Axis.horizontal
        ? _end!.dy - _start.dy
        : _end!.dx - _start.dx;
    snappingPoint.offset -= delta;
  }
}
