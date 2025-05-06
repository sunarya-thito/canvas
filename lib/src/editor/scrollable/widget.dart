import 'dart:math';
import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/widget/data.dart';
import 'package:flutter/widgets.dart';

class CanvasScrollbar extends StatefulWidget {
  final Axis direction;
  final CanvasScrollExtent scrollExtent;
  final ValueChanged<double> onScroll;

  const CanvasScrollbar({
    super.key,
    required this.direction,
    required this.scrollExtent,
    required this.onScroll,
  });

  @override
  State<CanvasScrollbar> createState() => _CanvasScrollbarState();
}

class _CanvasScrollbarState extends State<CanvasScrollbar> {
  @override
  Widget build(BuildContext context) {
    final theme = CanvasTheme.of(context);
    final resolvedPadding =
        theme.scrollbar.trackPadding.resolve(Directionality.of(context));

    return SizedBox(
      width: widget.direction == Axis.vertical
          ? (theme.scrollbar.thumbThickness + resolvedPadding.horizontal)
          : null,
      height: widget.direction == Axis.horizontal
          ? (theme.scrollbar.thumbThickness + resolvedPadding.vertical)
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double thumbLengthFactor = widget.scrollExtent.thumbLength;
          if (thumbLengthFactor >= 1) {
            return SizedBox.shrink();
          }
          var size = constraints.biggest;
          var viewportSize =
              widget.direction == Axis.horizontal ? size.width : size.height;
          double thumbLength = max(
              theme.scrollbar.minThumbLength, thumbLengthFactor * viewportSize);

          double thumbOffset = widget.scrollExtent.thumbOffset.clamp(0, 1) *
              (viewportSize - thumbLength);

          return Container(
            padding: resolvedPadding,
            decoration: theme.scrollbar.trackDecoration,
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left:
                      widget.direction == Axis.horizontal ? thumbOffset : null,
                  top: widget.direction == Axis.vertical ? thumbOffset : null,
                  width: widget.direction == Axis.horizontal
                      ? thumbLength
                      : theme.scrollbar.thumbThickness,
                  height: widget.direction == Axis.vertical
                      ? thumbLength
                      : theme.scrollbar.thumbThickness,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      double delta = widget.direction == Axis.horizontal
                          ? details.delta.dx
                          : details.delta.dy;
                      if (thumbLengthFactor == 0) {
                        widget.onScroll(-delta);
                        return;
                      }
                      widget.onScroll(-delta / thumbLengthFactor);
                    },
                    child: Container(
                      decoration: theme.scrollbar.thumbDecoration,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CanvasEditorScrollable extends StatelessWidget {
  final CanvasEditor editor;
  final Widget child;

  const CanvasEditorScrollable({
    super.key,
    required this.editor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: editor,
        builder: (context, _) {
          Size viewportSize = CanvasEditorWidgetData.of(context).viewportSize;
          Rect viewportBounds =
              editor.computeBounds(viewportSize).inflate(150 * editor.zoom);
          Rect editorBounds = Offset.zero & viewportSize;
          final theme = CanvasTheme.of(context);
          final resolvedPadding = theme.scrollbar.trackPadding.resolve(
            Directionality.of(context),
          );
          final double trackWidth =
              theme.scrollbar.thumbThickness + resolvedPadding.horizontal;
          final double trackHeight =
              theme.scrollbar.thumbThickness + resolvedPadding.vertical;
          return Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              PositionedDirectional(
                top: 0,
                end: 0,
                bottom: trackHeight,
                width: trackWidth,
                child: CanvasScrollbar(
                  direction: Axis.vertical,
                  scrollExtent: CanvasScrollExtent(
                    viewportMin: viewportBounds.top,
                    viewportMax: viewportBounds.bottom,
                    editorMin: editorBounds.top,
                    editorMax: editorBounds.bottom,
                  ),
                  onScroll: (value) {
                    editor.dragViewport(
                      Offset(0, value),
                    );
                  },
                ),
              ),
              PositionedDirectional(
                bottom: 0,
                start: 0,
                end: trackWidth,
                height: trackHeight,
                child: CanvasScrollbar(
                  direction: Axis.horizontal,
                  scrollExtent: CanvasScrollExtent(
                    viewportMin: viewportBounds.left,
                    viewportMax: viewportBounds.right,
                    editorMin: editorBounds.left,
                    editorMax: editorBounds.right,
                  ),
                  onScroll: (value) {
                    editor.dragViewport(
                      Offset(value, 0),
                    );
                  },
                ),
              ),
            ],
          );
        });
  }
}

class CanvasScrollExtent {
  // viewport is inside the editor and might go negative
  final double viewportMin;
  final double viewportMax;
  // editor is the whole editor size
  final double editorMin; // this usually is 0
  final double editorMax; // this is the size of the editor

  const CanvasScrollExtent({
    required this.viewportMin,
    required this.viewportMax,
    required this.editorMin,
    required this.editorMax,
  });

  double get thumbLength {
    double viewportSize = viewportMax.clamp(editorMin, editorMax) -
        viewportMin.clamp(editorMin, editorMax);
    if (viewportSize <= 0) {
      return 0;
    }
    return viewportSize / (viewportMax - viewportMin);
  }

  double get thumbOffset {
    double viewportSize = viewportMax - viewportMin;
    double editorSize = this.editorMax - editorMin;
    double editorMax = this.editorMax - viewportSize;
    if (editorSize > viewportSize) {
      return viewportMax;
    }
    return viewportMin / editorMax;
  }
}
