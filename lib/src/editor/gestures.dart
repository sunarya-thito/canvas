import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

abstract class EditorGesture {
  const EditorGesture();
  EditorGestureState createState(
      {required CanvasEditorHandler editor});

  void onPointerScroll(PointerScrollEvent event, CanvasEditorHandler editor) {
    var zoomDelta = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
    editor.transform = editor.transform.zoomAt(
      event.localPosition,
      delta: zoomDelta,
    );
  }
}

abstract class EditorGestureState {
  final CanvasEditorHandler editor;
  final Offset startPosition;

  EditorGestureState({
    required this.editor,
    required this.startPosition,
  });

  Ticker? _ticker;

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

  void onTick(Duration elapsed) {}

  Map<Type, GestureRecognizerFactory> get gestures {
    Map<Type, GestureRecognizerFactory> map = {};
    final tapGestureRecognizer = this.tapGestureRecognizer;
    if (tapGestureRecognizer != null) {
      map[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        tapGestureRecognizer,
      );
    }
    final panGestureRecognizer = this.panGestureRecognizer;
    if (panGestureRecognizer != null) {
      map[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(),
        panGestureRecognizer,
      );
    }
    final scaleGestureRecognizer = this.scaleGestureRecognizer;
    if (scaleGestureRecognizer != null) {
      map[ScaleGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => ScaleGestureRecognizer(),
        scaleGestureRecognizer,
      );
    }
  }

  GestureRecognizerFactoryInitializer<TapGestureRecognizer>? get tapGestureRecognizer => null;
  GestureRecognizerFactoryInitializer<PanGestureRecognizer>? get panGestureRecognizer => null;
  GestureRecognizerFactoryInitializer<ScaleGestureRecognizer>? get scaleGestureRecognizer => null;

  void dispose() {
    editor.stopMouseGesture(this);
    stopTicker();
  }
}

class EditorMoveGesture extends EditorGesture {
  const EditorMoveGesture();
  @override
  EditorGestureState createState(
      {required Offset localPosition, required CanvasEditorHandler editor}) {
    return EditorMoveGestureHandler(
      editor: editor,
      startPosition: localPosition,
    );
  }
}

class EditorMoveGestureHandler extends EditorGestureState {
  EditorMoveGestureHandler({
    required super.editor,
    required super.startPosition,
  });

  bool _dragging = false;
  SelectionBox? _selectionRect;

  @override
  void onPointerDown(PointerDownEvent event) {
  
    GestureDetector(
      onPanStart: (details) {
      },
      onTertiaryTapUp: ,
    )
    if (event.buttons == kTertiaryButton) {
      _dragging = true;
    }
  }

  void onPanStart(DragStartDetails details) {
    _selectionRect = SelectionBox.local(start: details.localPosition);
    editor.addSelectionRect(_selectionRect!);
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_selectionRect != null) {
      _selectionRect!.update(end: details.localPosition);
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (_selectionRect != null) {
      editor.removeSelectionRect(_selectionRect!);
      editor.selectFromRect(_selectionRect!);
      _selectionRect = null;
    }
  }

  void onPanCancel() {
    if (_selectionRect != null) {
      editor.removeSelectionRect(_selectionRect!);
      _selectionRect = null;
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    if (_dragging) {
      editor.transform = editor.transform.drag(event.localDelta);
    }
  }

  @override
  void onPointerCancel(PointerCancelEvent event) {
    dispose();
  }

  @override
  void onPointerUp(PointerUpEvent event) {
    dispose();
  }
}

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
