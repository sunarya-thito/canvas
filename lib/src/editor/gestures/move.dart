import 'package:canvas/canvas.dart';
import 'package:flutter/src/services/mouse_cursor.dart';

class EditorMoveDragGesture extends EditorGesture {
  const EditorMoveDragGesture();
  @override
  EditorGestureSession createSession(CanvasEditor editor) {
    return EditorMoveDragGestureSession(editor);
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;
  @override
  bool get interceptPointerEvents => true;
}

class EditorMoveDragGestureSession extends EditorGestureSession {
  EditorMoveDragGestureSession(super.editor);

  @override
  MouseCursor get cursor => SystemMouseCursors.grabbing;

  @override
  void onDragUpdate() {
    editor.offset += delta.delta;
  }
}
