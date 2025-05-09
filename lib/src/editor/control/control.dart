import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';

abstract class EditorControlSession {
  CanvasEditor? _editor;
  Delta? _delta;
  Size? _viewportSize;

  CanvasEditor get editor {
    assert(_editor != null, 'Session not started');
    return _editor!;
  }

  Size get viewportSize {
    assert(_viewportSize != null, 'Session not started');
    return _viewportSize!;
  }

  Delta get delta {
    assert(_delta != null, 'Session not started');
    return _delta!;
  }

  void handleStartSession(CanvasEditor editor, Size viewportSize) {
    assert(_editor == null, 'Session already started');
    _editor = editor;
    _viewportSize = viewportSize;
  }

  void handleDragStart(Offset position, Size viewportSize) {
    _delta = Delta(start: position, end: position);
    _viewportSize = viewportSize;
    onDragStart();
  }

  void handleDragUpdate(Offset position, Size viewportSize) {
    _delta = _delta!.copyWith(end: position);
    _viewportSize = viewportSize;
    onDragUpdate();
  }

  void handleDragEnd() {
    onDragEnd();
    _delta = null;
  }

  void handleEditorUpdate() {
    onEditorUpdate();
  }

  void handleDragCancel() {
    onDragCancel();
    _delta = null;
  }

  void onDragStart() {}
  void onDragUpdate() {}
  void onDragEnd() {}
  void onDragCancel() {}
  void onEditorUpdate() {}

  void visitSnapAnchor(SnapAnchorVisitor visitor);

  bool get shiftViewport => false;
}
