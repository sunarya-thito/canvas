import 'package:canvas/canvas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

abstract class EditorDragGesture {
  const EditorDragGesture();
  EditorDragGestureSession createState({required CanvasEditorHandler editor});
  MouseCursor get cursor => MouseCursor.defer;
  bool get allowEditorInteraction => true;
}

abstract class EditorDragGestureSession {
  final CanvasEditorHandler editor;

  EditorDragGestureSession({
    required this.editor,
  });

  Ticker? _ticker;
  Offset? _shift;

  void startTicker() {
    if (_ticker != null) {
      return;
    }
    _lastTick = null;
    _ticker = editor.createTicker(onTick);
    _ticker!.start();
  }

  void stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void _handleCursorPosition(Offset position) {
    Size viewportSize = editor.viewportSize;
    double shiftX = 0;
    double shiftY = 0;

    EdgeInsets shiftPadding = EdgeInsets.all(20);

    double verticalMin = shiftPadding.top;
    double verticalMax = viewportSize.height - shiftPadding.bottom;
    double horizontalMin = shiftPadding.left;
    double horizontalMax = viewportSize.width - shiftPadding.right;

    if (position.dy < verticalMin) {
      shiftY = -(verticalMin - position.dy) / shiftPadding.top;
    } else if (position.dy > verticalMax) {
      shiftY = (position.dy - verticalMax) / shiftPadding.bottom;
    }

    if (position.dx < horizontalMin) {
      shiftX = -(horizontalMin - position.dx) / shiftPadding.left;
    } else if (position.dx > horizontalMax) {
      shiftX = (position.dx - horizontalMax) / shiftPadding.right;
    }
    if (shiftX != 0 || shiftY != 0) {
      _shift = Offset(-shiftX, -shiftY);
      startTicker();
    } else {
      stopTicker();
    }
  }

  Duration? _lastTick;
  void onTick(Duration elapsed) {
    Duration delta = elapsed - (_lastTick ?? Duration.zero);
    if (_shift != null) {
      var shift = Offset(
        _shift!.dx * delta.inMilliseconds / 2,
        _shift!.dy * delta.inMilliseconds / 2,
      );

      onShift(shift);
    }
    _lastTick = elapsed;
  }

  MouseCursor get cursor => MouseCursor.defer;

  void onShift(Offset shift) {
    editor.dragViewport(shift);
  }

  void onDragStart(Offset start) {
    _handleCursorPosition(start);
  }

  void onDrag(Offset start, Offset end) {
    _handleCursorPosition(end);
  }

  void onDragRelease(Offset start, Offset end) {}
  void onDragCancel() {}

  void dispose() {
    editor.stopMouseGesture(this);
    stopTicker();
  }
}

class EditorSelectDragGesture extends EditorDragGesture {
  const EditorSelectDragGesture();
  @override
  EditorDragGestureSession createState({required CanvasEditorHandler editor}) {
    return EditorSelectDragGestureHandler(
      editor: editor,
    );
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;
}

class EditorSelectDragGestureHandler extends EditorDragGestureSession {
  EditorSelectDragGestureHandler({
    required super.editor,
  });

  late SelectionBox _selectionRect;
  Selection? _oldSelection;

  @override
  void onDragStart(Offset start) {
    super.onDragStart(start);
    _oldSelection = editor.localSelection;
    _selectionRect = SelectionBox.local(start: start);
    editor.addSelectionRect(_selectionRect);
  }

  @override
  void onShift(Offset shift) {
    super.onShift(shift);
    _selectionRect.start.value += shift;
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDrag(Offset start, Offset end) {
    super.onDrag(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDragRelease(Offset start, Offset end) {
    super.onDragRelease(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
    editor.removeSelectionRect(_selectionRect);
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDragCancel() {
    super.onDragCancel();
    editor.removeSelectionRect(_selectionRect);
    editor.localSelection = _oldSelection;
  }
}

class EditorMoveDragGesture extends EditorDragGesture {
  const EditorMoveDragGesture();
  @override
  EditorDragGestureSession createState({required CanvasEditorHandler editor}) {
    return EditorMoveDragGestureHandler(
      editor: editor,
    );
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  bool get allowEditorInteraction => false;
}

class EditorMoveDragGestureHandler extends EditorDragGestureSession {
  EditorMoveDragGestureHandler({
    required super.editor,
  });

  @override
  void onDrag(Offset start, Offset end) {
    super.onDrag(start, end);
    editor.dragViewport(end - start);
  }

  @override
  void onShift(Offset shift) {
    editor.transform = editor.transform.copyWith(
      offset: editor.transform.offset - shift,
    );
  }

  @override
  MouseCursor get cursor {
    return SystemMouseCursors.grabbing;
  }
}
