import 'package:canvas/canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

abstract class EditorMouseGesture {
  EditorMouseGestureHandler createSession(
      {required Offset localPosition,
      required CanvasItemState parent,
      required CanvasEditorHandler editor});
}

abstract class EditorMouseGestureHandler {
  final CanvasItemState parent;
  final CanvasEditorHandler editor;
  final Offset startPosition;

  EditorMouseGestureHandler({
    required this.parent,
    required this.editor,
    required this.startPosition,
  });

  void onPressed(PointerDownEvent event) {}
  void onMoved(PointerMoveEvent event) {}
  void onReleased(PointerUpEvent event) {}
  void onCanceled(PointerCancelEvent event) {}

  void dispose() {
    editor.stopMouseGesture(this);
  }
}

abstract class EditorGestureHandler {
  const EditorGestureHandler();

  Widget wrap(
      BuildContext context, Widget child, CanvasEditorController controller);
}

class DesktopEditorGestureHandler extends EditorGestureHandler {
  const DesktopEditorGestureHandler();

  @override
  Widget wrap(
      BuildContext context, Widget child, CanvasEditorController controller) {
    return Stack(
      children: [
        Positioned.fill(
          child: child,
        ),
        Positioned.fill(
          child: _DesktopEditorGestureHandlerWidget(
            controller: controller,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _DesktopEditorGestureHandlerWidget extends StatefulWidget {
  final CanvasEditorController controller;
  final Widget child;

  const _DesktopEditorGestureHandlerWidget({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<_DesktopEditorGestureHandlerWidget> createState() =>
      _DesktopEditorGestureHandlerWidgetState();
}

class _DesktopEditorGestureHandlerWidgetState
    extends State<_DesktopEditorGestureHandlerWidget> {
  bool _dragging = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.buttons == kTertiaryButton) {
          _dragging = true;
        }
      },
      onPointerMove: (event) {
        if (_dragging) {
          widget.controller.value = widget.controller.value.drag(event.delta);
        }
      },
      onPointerUp: (event) {
        _dragging = false;
      },
      onPointerCancel: (event) {
        _dragging = false;
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          Offset position = event.localPosition;
          widget.controller.value = widget.controller.value.zoomAt(
            position,
            delta: event.scrollDelta.dy < 0 ? 0.1 : -0.1,
          );
        }
      },
      child: widget.child,
    );
  }
}
