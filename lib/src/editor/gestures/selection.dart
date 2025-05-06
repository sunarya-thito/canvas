import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/selection/box.dart';
import 'package:canvas/src/editor/selection/selection.dart';

class EditorSelectDragGesture extends EditorGesture {
  const EditorSelectDragGesture();
  @override
  EditorGestureSession createSession(CanvasEditor editor) {
    return EditorSelectDragGestureSession(editor);
  }
}

class EditorSelectDragGestureSession extends EditorGestureSession {
  EditorSelectDragGestureSession(super.editor);

  late SelectionBox _selectionRect;
  Selection? _oldSelection;

  @override
  void onDragStart() {
    _oldSelection = editor.localSelection;
    _selectionRect = SelectionBox.local(start: delta.start);
    editor.addSelectionRect(_selectionRect);
  }

  @override
  void onDragUpdate() {
    _selectionRect.end.value = delta.end;
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDragEnd() {
    editor.removeSelectionRect(_selectionRect);
  }

  @override
  void onDragCancel() {
    editor.removeSelectionRect(_selectionRect);
    editor.localSelection = _oldSelection;
  }
}
