import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

abstract class EditorDragGesture {
  const EditorDragGesture();
  EditorDragGestureSession createState({required CanvasEditorHandler editor});
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
      _shift = Offset(-shiftX * 3, -shiftY * 3);
      startTicker();
    } else {
      stopTicker();
    }
  }

  void onTick(Duration elapsed) {
    if (_shift != null) {
      editor.shiftViewport(_shift!);
      onShift(_shift!);
    }
  }

  void onShift(Offset shift) {}

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
}

class EditorSelectDragGestureHandler extends EditorDragGestureSession {
  EditorSelectDragGestureHandler({
    required super.editor,
  });

  late SelectionBox _selectionRect;

  @override
  void onDragStart(Offset start) {
    super.onDragStart(start);
    _selectionRect = SelectionBox.local(start: start);
    editor.addSelectionRect(_selectionRect);
  }

  @override
  void onShift(Offset shift) {
    super.onShift(shift);
    _selectionRect.start.value += shift;
  }

  @override
  void onDrag(Offset start, Offset end) {
    super.onDrag(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
  }

  @override
  void onDragRelease(Offset start, Offset end) {
    super.onDragRelease(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
    editor.removeSelectionRect(_selectionRect);
    editor.selectFromRect(_selectionRect);
  }

  @override
  void onDragCancel() {
    super.onDragCancel();
    editor.removeSelectionRect(_selectionRect);
  }
}

// class EditorMoveGesture extends EditorDragGesture {
//   const EditorMoveGesture();
//   @override
//   EditorDragGestureSession createState(
//       {required Offset localPosition, required CanvasEditorHandler editor}) {
//     return EditorMoveGestureHandler(
//       editor: editor,
//       startPosition: localPosition,
//     );
//   }
// }

// class EditorMoveGestureHandler extends EditorDragGestureSession {
//   EditorMoveGestureHandler({
//     required super.editor,
//     required super.startPosition,
//   });

//   bool _dragging = false;
//   SelectionBox? _selectionRect;

//   @override
//   void onPointerDown(PointerDownEvent event) {

//     GestureDetector(
//       onPanStart: (details) {
//       },
//       onTertiaryTapUp: ,
//     )
//     if (event.buttons == kTertiaryButton) {
//       _dragging = true;
//     }
//   }

//   void onPanStart(DragStartDetails details) {
//     _selectionRect = SelectionBox.local(start: details.localPosition);
//     editor.addSelectionRect(_selectionRect!);
//   }

//   void onPanUpdate(DragUpdateDetails details) {
//     if (_selectionRect != null) {
//       _selectionRect!.update(end: details.localPosition);
//     }
//   }

//   void onPanEnd(DragEndDetails details) {
//     if (_selectionRect != null) {
//       editor.removeSelectionRect(_selectionRect!);
//       editor.selectFromRect(_selectionRect!);
//       _selectionRect = null;
//     }
//   }

//   void onPanCancel() {
//     if (_selectionRect != null) {
//       editor.removeSelectionRect(_selectionRect!);
//       _selectionRect = null;
//     }
//   }

//   @override
//   void onPointerMove(PointerMoveEvent event) {
//     if (_dragging) {
//       editor.transform = editor.transform.drag(event.localDelta);
//     }
//   }

//   @override
//   void onPointerCancel(PointerCancelEvent event) {
//     dispose();
//   }

//   @override
//   void onPointerUp(PointerUpEvent event) {
//     dispose();
//   }
// }

// abstract class EditorGestureHandler {
//   const EditorGestureHandler();

//   Widget wrap(
//       BuildContext context, Widget child, CanvasEditorController controller);
// }

// class DesktopEditorGestureHandler extends EditorGestureHandler {
//   const DesktopEditorGestureHandler();

//   @override
//   Widget wrap(
//       BuildContext context, Widget child, CanvasEditorController controller) {
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: child,
//         ),
//         Positioned.fill(
//           child: _DesktopEditorGestureHandlerWidget(
//             controller: controller,
//             child: child,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _DesktopEditorGestureHandlerWidget extends StatefulWidget {
//   final CanvasEditorController controller;
//   final Widget child;

//   const _DesktopEditorGestureHandlerWidget({
//     Key? key,
//     required this.controller,
//     required this.child,
//   }) : super(key: key);

//   @override
//   State<_DesktopEditorGestureHandlerWidget> createState() =>
//       _DesktopEditorGestureHandlerWidgetState();
// }

// class _DesktopEditorGestureHandlerWidgetState
//     extends State<_DesktopEditorGestureHandlerWidget> {
//   bool _dragging = false;
//   @override
//   Widget build(BuildContext context) {
//     return Listener(
//       behavior: HitTestBehavior.translucent,
//       onPointerDown: (event) {
//         if (event.buttons == kTertiaryButton) {
//           _dragging = true;
//         }
//       },
//       onPointerMove: (event) {
//         if (_dragging) {
//           widget.controller.value = widget.controller.value.drag(event.delta);
//         }
//       },
//       onPointerUp: (event) {
//         _dragging = false;
//       },
//       onPointerCancel: (event) {
//         _dragging = false;
//       },
//       onPointerSignal: (event) {
//         if (event is PointerScrollEvent) {
//           Offset position = event.localPosition;
//           widget.controller.value = widget.controller.value.zoomAt(
//             position,
//             delta: event.scrollDelta.dy < 0 ? 0.1 : -0.1,
//           );
//         }
//       },
//       child: widget.child,
//     );
//   }
// }
