import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

abstract class EditorGesture {
  const EditorGesture();
  EditorGestureSession createSession(CanvasEditor editor);
  bool get interceptPointerEvents => false;
  MouseCursor get cursor => MouseCursor.defer;
  bool get allowSnapping => false;
}

abstract class EditorGestureSession with ChangeNotifier {
  final CanvasEditor editor;

  EditorGestureSession(this.editor);

  MouseCursor? get cursor => null;

  Delta? _delta;
  Size? _viewportSize;

  void handleDragStart(Offset position, Size viewportSize) {
    position = viewportGlobalToLocal(editor, viewportSize, position);
    _delta = Delta(start: position, end: position);
    _viewportSize = viewportSize;
    onDragStart();
  }

  void handleDragUpdate(Offset position, Size viewportSize) {
    position = viewportGlobalToLocal(editor, viewportSize, position);
    _delta = _delta!.copyWith(end: position);
    _viewportSize = viewportSize;
    onDragUpdate();
  }

  void handleDragEnd() {
    onDragEnd();
    _delta = null;
  }

  void handleShift(Offset delta) {
    _delta = _delta!.copyWith(end: _delta!.end + delta);
    onDragUpdate();
  }

  void handleDragCancel() {
    onDragCancel();
    _delta = null;
  }

  Size get viewportSize {
    assert(_viewportSize != null, 'Session not started');
    return _viewportSize!;
  }

  Delta get delta {
    assert(_delta != null, 'Session not started');
    return _delta!.transform(editor.computeTransform(_viewportSize!));
  }

  void onDragStart() {}
  void onDragUpdate() {}
  void onDragEnd() {}
  void onDragCancel() {}
}
