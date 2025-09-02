import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

typedef SnapAnchorHost = Function(SnapAnchorVisitor visitor);

String optimalDoubleString(double d) {
  // do not use d.toInt() == d method,
  String s = d.toStringAsFixed(2);
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  }
  return s;
}

Offset viewportLocalToGlobal(
    CanvasEditor editor, Size viewportSize, Offset offset) {
  Offset editorCenter = Offset(
    viewportSize.width / 2,
    viewportSize.height / 2,
  );
  Matrix4 transform = Matrix4.identity();
  transform.translate(editor.offset.dx, editor.offset.dy);
  transform.scale(editor.zoom, editor.zoom);
  transform.translate(editorCenter.dx, editorCenter.dy);
  return transformOffset(offset, transform);
}

Offset viewportGlobalToLocal(
    CanvasEditor editor, Size viewportSize, Offset offset) {
  Offset editorCenter = Offset(
    viewportSize.width / 2,
    viewportSize.height / 2,
  );
  Matrix4 transform = Matrix4.identity();
  transform.translate(-editorCenter.dx, -editorCenter.dy);
  transform.scale(1 / editor.zoom, 1 / editor.zoom);
  transform.translate(-editor.offset.dx, -editor.offset.dy);
  return transformOffset(offset, transform);
}

class Delta {
  static Delta zero = const Delta(start: Offset.zero, end: Offset.zero);
  // the start and end must be at editor local coordinate (after translated and scaled by its transform)
  final Offset start;
  final Offset end;

  const Delta({
    required this.start,
    required this.end,
  });

  const Delta.fromOffset(Offset offset)
      : start = Offset.zero,
        end = offset;

  Delta copyWith({
    Offset? start,
    Offset? end,
  }) {
    return Delta(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Delta shift(Offset delta) {
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

  Delta transform(Matrix4 transform) {
    return Delta(
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
