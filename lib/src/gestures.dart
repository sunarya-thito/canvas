import 'package:canvas/canvas.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasGestures {
  const CanvasGestures();
  Widget wrapViewport(
      BuildContext context, Widget child, CanvasViewportHandle handle);
}

class DesktopCanvasGestures extends CanvasGestures {
  final int button;
  final bool Function(PointerEvent event)? shouldHandleEvent;
  const DesktopCanvasGestures({
    this.shouldHandleEvent,
    this.button = MousePanGesture.tertiaryButton,
  });
  @override
  Widget wrapViewport(
      BuildContext context, Widget child, CanvasViewportHandle handle) {
    return DesktopCanvasGesturesWidget(
      button: button,
      handle: handle,
      shouldHandleEvent: shouldHandleEvent,
      child: child,
    );
  }
}

class DesktopCanvasGesturesWidget extends StatefulWidget {
  final int button;
  final Widget child;
  final CanvasViewportHandle handle;
  final bool Function(PointerEvent event)? shouldHandleEvent;

  const DesktopCanvasGesturesWidget({
    super.key,
    required this.button,
    required this.child,
    required this.handle,
    this.shouldHandleEvent,
  });

  @override
  State<DesktopCanvasGesturesWidget> createState() =>
      _DesktopCanvasGesturesWidgetState();
}

class _DesktopCanvasGesturesWidgetState
    extends State<DesktopCanvasGesturesWidget> with CanvasElementDragger {
  @override
  void handleDragAdjustment(Offset delta) {
    widget.handle.drag(delta);
    widget.handle.updateSelectSession(-delta);
  }

  Offset _transform(Offset offset) {
    offset = offset - widget.handle.canvasOffset;
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (widget.shouldHandleEvent?.call(event) ??
            (event is PointerScrollEvent)) {
          var scrollEvent = event as PointerScrollEvent;
          final zoomDelta = scrollEvent.scrollDelta.dy < 0 ? 0.1 : -0.1;
          var localPosition = scrollEvent.localPosition;
          localPosition =
              _transform(localPosition) / widget.handle.transform.zoom;
          widget.handle.zoomAt(localPosition, zoomDelta);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: widget.handle.enableInstantSelection
            ? (details) {
                var localPosition = details.localPosition;
                localPosition = _transform(localPosition);
                widget.handle.instantSelection(localPosition);
              }
            : null,
        child: PanGesture(
          onPanStart: (details) {
            var localPosition = details.localPosition;
            localPosition = _transform(localPosition);
            widget.handle.startSelectSession(localPosition);
            widget.handle.startDraggingSession(this);
          },
          onPanUpdate: (details) {
            var localPosition = details.localPosition;
            localPosition = _transform(localPosition);
            widget.handle.updateSelectSession(details.delta);
          },
          onPanCancel: () {
            widget.handle.cancelSelectSession();
            widget.handle.endDraggingSession(this);
          },
          onPanEnd: (details) {
            widget.handle.endSelectSession();
            widget.handle.endDraggingSession(this);
          },
          child: MousePanGesture(
            button: widget.button,
            onPanUpdate: (details) {
              widget.handle.drag(details.delta);
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
