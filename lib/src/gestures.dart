import 'package:canvas/canvas.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
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
  final EdgeInsets selectionPadding;
  final double scrollSpeed;

  const DesktopCanvasGesturesWidget({
    super.key,
    required this.button,
    required this.child,
    required this.handle,
    this.shouldHandleEvent,
    this.selectionPadding = const EdgeInsets.all(64),
    this.scrollSpeed = 0.01,
  });

  @override
  State<DesktopCanvasGesturesWidget> createState() =>
      _DesktopCanvasGesturesWidgetState();
}

class _DesktopCanvasGesturesWidgetState
    extends State<DesktopCanvasGesturesWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late Duration _lastTime;
  Offset? _lastOffset;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void _start(Offset offset) {
    if (_ticker.isActive) return;
    _lastTime = Duration.zero;
    _lastOffset = offset;
    _ticker.start();
  }

  void _stop() {
    if (!_ticker.isActive) return;
    _ticker.stop();
  }

  void _tick(Duration elapsed) {
    var delta = elapsed - _lastTime;
    var lastOffset = _lastOffset;
    if (lastOffset == null) return;
    double topDiff = lastOffset.dy - widget.selectionPadding.top;
    double bottomDiff = widget.handle.size.height -
        lastOffset.dy -
        widget.selectionPadding.bottom;
    double leftDiff = lastOffset.dx - widget.selectionPadding.left;
    double rightDiff = widget.handle.size.width -
        lastOffset.dx -
        widget.selectionPadding.right;
    if (topDiff > 0 && leftDiff > 0 && bottomDiff > 0 && rightDiff > 0) {
      return;
    }
    double dxScroll = 0;
    double dyScroll = 0;
    double speed = (widget.scrollSpeed / 1000) * delta.inMilliseconds;
    if (topDiff <= 0) {
      dyScroll = -topDiff * speed;
    } else if (bottomDiff <= 0) {
      dyScroll = bottomDiff * speed;
    }
    if (leftDiff <= 0) {
      dxScroll = -leftDiff * speed;
    } else if (rightDiff <= 0) {
      dxScroll = rightDiff * speed;
    }
    widget.handle.drag(Offset(dxScroll, dyScroll));
    widget.handle.updateSelectSession(-Offset(dxScroll, dyScroll));
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
                widget.handle.instantSelection(
                    localPosition / widget.handle.transform.zoom);
              }
            : null,
        child: PanGesture(
          onPanStart: (details) {
            var localPosition = details.localPosition;
            localPosition = _transform(localPosition);
            widget.handle.startSelectSession(localPosition);
            _start(details.localPosition);
          },
          onPanUpdate: (details) {
            var localPosition = details.localPosition;
            localPosition = _transform(localPosition);
            widget.handle.updateSelectSession(details.delta);
            _lastOffset = details.localPosition;
          },
          onPanCancel: () {
            widget.handle.cancelSelectSession();
            _stop();
          },
          onPanEnd: (details) {
            widget.handle.endSelectSession();
            _stop();
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
