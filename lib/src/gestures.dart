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
  const DesktopCanvasGestures({this.button = MousePanGesture.tertiaryButton});
  @override
  Widget wrapViewport(
      BuildContext context, Widget child, CanvasViewportHandle handle) {
    return DesktopCanvasGesturesWidget(
      button: button,
      handle: handle,
      child: child,
    );
  }
}

class DesktopCanvasGesturesWidget extends StatefulWidget {
  final int button;
  final Widget child;
  final CanvasViewportHandle handle;

  const DesktopCanvasGesturesWidget({
    super.key,
    required this.button,
    required this.child,
    required this.handle,
  });

  @override
  State<DesktopCanvasGesturesWidget> createState() =>
      _DesktopCanvasGesturesWidgetState();
}

class _DesktopCanvasGesturesWidgetState
    extends State<DesktopCanvasGesturesWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final canvasAlignment =
        widget.handle.alignment.resolve(Directionality.of(context));
    final size = widget.handle.size;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final zoomDelta = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
          var localPosition = event.localPosition;
          final origin = canvasAlignment.alongSize(size);
          localPosition = localPosition -
              widget.handle.transform.offset * widget.handle.transform.zoom -
              origin;
          localPosition = localPosition / widget.handle.transform.zoom;
          widget.handle.transform =
              widget.handle.transform.zoomAt(localPosition, zoomDelta);
        }
      },
      child: PanGesture(
        onPanStart: (details) {
          var localPosition = details.localPosition;
          final origin = canvasAlignment.alongSize(size);
          localPosition = localPosition -
              widget.handle.transform.offset * widget.handle.transform.zoom -
              origin;
          localPosition = localPosition / widget.handle.transform.zoom;
          widget.handle.startSelectSession(localPosition);
        },
        onPanUpdate: (details) {
          var localPosition = details.localPosition;
          final origin = canvasAlignment.alongSize(size);
          localPosition = localPosition -
              widget.handle.transform.offset * widget.handle.transform.zoom -
              origin;
          localPosition = localPosition / widget.handle.transform.zoom;
          widget.handle.updateSelectSession(localPosition);
        },
        onPanCancel: () {
          widget.handle.cancelSelectSession();
        },
        onPanEnd: (details) {
          widget.handle.endSelectSession();
        },
        child: MousePanGesture(
          button: widget.button,
          onPanUpdate: (details) {
            widget.handle.transform = widget.handle.transform
                .drag(details.delta / widget.handle.transform.zoom);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
