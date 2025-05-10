import 'package:animation_kit/animation_kit.dart';
import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/editor.dart';
import 'package:canvas/src/editor/grid/grid.dart';
import 'package:canvas/src/editor/grid/widget.dart';
import 'package:canvas/src/editor/ruler/widget.dart';
import 'package:canvas/src/editor/scrollable/widget.dart';
import 'package:canvas/src/editor/selection/widget.dart';
import 'package:canvas/src/editor/snap/absolute.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:canvas/src/editor/widget/data.dart';
import 'package:canvas/src/widget_util.dart';
import 'package:data_widget/data_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class CanvasEditorWidget extends StatefulWidget {
  final CanvasEditor editor;
  final FocusNode? focusNode;
  final bool scrollAsZoom;
  final bool showRuler;

  const CanvasEditorWidget({
    super.key,
    required this.editor,
    this.focusNode,
    this.scrollAsZoom = true,
    this.showRuler = true,
  });

  @override
  State<CanvasEditorWidget> createState() => _CanvasEditorWidgetState();
}

class _CanvasEditorWidgetState extends State<CanvasEditorWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _viewportKey = GlobalKey();
  late Ticker _ticker;
  late FocusNode _focusNode;
  Duration? _lastTickTime;
  bool _pointerDown = false;

  void _onTick(Duration elapsed) {
    var delta = elapsed - (_lastTickTime ?? elapsed);
    widget.editor.tick(delta);
    _lastTickTime = elapsed;
  }

  @override
  void initState() {
    super.initState();
    _focusNode =
        widget.focusNode ?? FocusNode(debugLabel: 'CanvasEditorWidget');
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CanvasTheme.of(context);
    return Actions(
        actions: {
          CanvasDeleteSelectedObjectsIntent: Action.overridable(
            defaultAction: CanvasDeleteSelectedObjectsAction(
              editor: widget.editor,
            ),
            context: context,
          ),
          CanvasSelectAllIntent: Action.overridable(
            defaultAction: CanvasSelectAllAction(
              editor: widget.editor,
            ),
            context: context,
          ),
          CanvasDragIntent: Action.overridable(
            defaultAction: CanvasDragAction(
              editor: widget.editor,
            ),
            context: context,
          ),
          CanvasResizeIntent: Action.overridable(
            defaultAction: CanvasResizeAction(
              editor: widget.editor,
            ),
            context: context,
          ),
        },
        child: AnimatedValueBuilder(
          value: widget.showRuler ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          builder: (context, showRuler, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                var size = Size(
                  constraints.biggest.width -
                      theme.ruler.rulerWidth * showRuler,
                  constraints.biggest.height -
                      theme.ruler.rulerWidth * showRuler,
                );
                return Data.inherit(
                  data: CanvasEditorWidgetData(
                    viewportSize: size,
                    editor: widget.editor,
                    globalToLocal: (position) {
                      var renderBox = _viewportKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      assert(renderBox != null,
                          'CanvasEditorWidget must be mounted to get globalToLocal');
                      return renderBox!.globalToLocal(position);
                    },
                  ),
                  child: Focus(
                    focusNode: _focusNode,
                    child: ListenableBuilder(
                      listenable: widget.editor,
                      builder: (context, _) {
                        Matrix4 transform =
                            widget.editor.computeTransform(size);
                        return CanvasRuler(
                          editor: widget.editor,
                          showRuler: showRuler,
                          editorTransform: transform,
                          snapAnchors: widget.editor.rulerSnapAnchors,
                          selection: widget.editor.localSelection,
                          child: CanvasEditorScrollable(
                            editor: widget.editor,
                            child: MouseRegion(
                              cursor: widget.editor.gestureSession?.cursor ??
                                  widget.editor.gesture.cursor,
                              hitTestBehavior: HitTestBehavior.translucent,
                              child: RawGestureDetector(
                                behavior: HitTestBehavior.translucent,
                                gestures: {
                                  TertiaryPanGestureRecognizer:
                                      GestureRecognizerFactoryWithHandlers<
                                          TertiaryPanGestureRecognizer>(
                                    () => TertiaryPanGestureRecognizer(),
                                    (instance) {
                                      instance.onUpdate = (details) {
                                        widget.editor
                                            .dragViewport(details.delta);
                                      };
                                    },
                                  ),
                                  PanGestureRecognizer:
                                      GestureRecognizerFactoryWithHandlers<
                                          PanGestureRecognizer>(
                                    () => PanGestureRecognizer(),
                                    (PanGestureRecognizer instance) {
                                      instance.onStart = (details) {
                                        if (widget.editor.selectionMode !=
                                                CanvasSelectionMode.multiple &&
                                            !widget.editor.gesture
                                                .interceptPointerEvents) {
                                          widget.editor.localSelection = null;
                                        }
                                        widget.editor.startGestureSession(
                                            details.localPosition, size);
                                      };
                                      instance.onUpdate = (details) {
                                        widget.editor.updateGestureSession(
                                            details.localPosition, size);
                                      };
                                      instance.onEnd = (details) {
                                        widget.editor.endGestureSession();
                                      };
                                      instance.onCancel = () {
                                        widget.editor.cancelGestureSession();
                                      };
                                    },
                                  ),
                                },
                                child: Stack(
                                  key: _viewportKey,
                                  fit: StackFit.passthrough,
                                  children: [
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          if (widget.editor.gesture
                                              .interceptPointerEvents) {
                                            return;
                                          }
                                          widget.editor.localSelection = null;
                                        },
                                      ),
                                    ),
                                    GroupWidget(
                                      children: [
                                        Transform(
                                          transform: transform,
                                          child: widget.editor.rootState
                                              .renderEditor(
                                                  context, widget.editor),
                                        ),
                                        Transform(
                                          transform: transform,
                                          child: LayoutGridWidget(
                                            state: widget.editor.rootState,
                                            editor: widget.editor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    for (var selected
                                        in widget.editor.selections)
                                      Stack(
                                        fit: StackFit.passthrough,
                                        children: selected.groups.map(
                                          (group) {
                                            return SelectionTransformControlWidget(
                                              parentTransform: transform,
                                              editor: widget.editor,
                                              selection: selected,
                                              selectionGroup: group,
                                              zoom: widget.editor.zoom,
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    for (var selection
                                        in widget.editor.activeSelectionClients)
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: SelectionWidget(
                                          editor: widget.editor,
                                          selectionBox: selection,
                                        ),
                                      ),
                                    Builder(
                                      builder: (context) {
                                        var active =
                                            widget.editor.snappingResult;
                                        if (active == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return CustomPaint(
                                          painter: _ActiveSnapAnchorPainter(
                                            offset: widget.editor.offset,
                                            result: active,
                                            borderColor: theme
                                                .snap.activeSnapBorderColor,
                                            indicatorSize:
                                                theme.snap.indicatorSize,
                                            borderWidth: theme
                                                .snap.activeSnapBorderWidth,
                                            zoom: widget.editor.zoom,
                                            viewportSize: size,
                                          ),
                                        );
                                      },
                                    ),
                                    AbsorbPointer(
                                      absorbing: widget.editor.gesture
                                          .interceptPointerEvents,
                                    ),
                                    Listener(
                                      behavior: HitTestBehavior.translucent,
                                      onPointerSignal: (event) {
                                        if (event is PointerScrollEvent &&
                                            widget.scrollAsZoom) {
                                          var zoomDelta =
                                              event.scrollDelta.dy < 0
                                                  ? 0.1
                                                  : -0.1;
                                          widget.editor.zoomViewport(
                                              zoomDelta, size,
                                              focalPoint: event.localPosition);
                                        }
                                      },
                                      onPointerDown: (event) {
                                        _focusNode.requestFocus();
                                        _pointerDown = true;
                                      },
                                      onPointerUp: (event) {
                                        _pointerDown = false;
                                      },
                                      onPointerCancel: (event) {
                                        _pointerDown = false;
                                      },
                                      onPointerMove: (event) {
                                        if (_pointerDown) {
                                          widget.editor.handleCursorPosition(
                                              event.localPosition, size);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}

class _ActiveSnapAnchorPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double indicatorSize;
  final SnappingResult result;
  final Offset offset;
  final double zoom;
  final Size viewportSize;

  const _ActiveSnapAnchorPainter({
    required this.offset,
    required this.result,
    required this.borderColor,
    required this.indicatorSize,
    required this.borderWidth,
    required this.zoom,
    required this.viewportSize,
  });

  void _drawX(Offset offset, Canvas canvas, Paint paint) {
    Offset halfSize = Offset(indicatorSize / 2, indicatorSize / 2);
    Offset topLeft = offset - halfSize;
    Offset bottomRight = offset + halfSize;
    canvas.drawLine(topLeft, bottomRight, paint);
    canvas.drawLine(Offset(topLeft.dx, bottomRight.dy),
        Offset(bottomRight.dx, topLeft.dy), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.translate(offset.dx + viewportSize.width / 2 * zoom,
    //     offset.dy + viewportSize.height / 2 * zoom);

    Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    for (var entry in result.entries) {
      var sourceAnchor = entry.sourceAnchor;
      var targetAnchor = entry.targetAnchor;
      if (sourceAnchor is AbsoluteSnapAnchor &&
          targetAnchor is AbsoluteSnapAnchor) {
        var sourcePoint = sourceAnchor.point - result.snapDelta;
        var targetPoint = targetAnchor.point;
        sourcePoint = offset +
            viewportSize.center(Offset.zero) * zoom +
            sourcePoint * zoom;
        targetPoint = offset +
            viewportSize.center(Offset.zero) * zoom +
            targetPoint * zoom;
        _drawX(targetPoint, canvas, paint);
        _drawX(sourcePoint, canvas, paint);
        canvas.drawLine(sourcePoint, targetPoint, paint);
      } else {
        var direction = entry.targetLine.direction;
        var offset = entry.targetLine.offset;
        if (direction == Axis.vertical) {
          offset =
              this.offset.dx + viewportSize.width / 2 * zoom + offset * zoom;
        } else {
          offset =
              this.offset.dy + viewportSize.height / 2 * zoom + offset * zoom;
        }
        var start =
            direction == Axis.vertical ? Offset(offset, 0) : Offset(0, offset);
        var end = direction == Axis.vertical
            ? Offset(offset, viewportSize.height)
            : Offset(viewportSize.width, offset);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveSnapAnchorPainter oldDelegate) {
    return result != oldDelegate.result ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        indicatorSize != oldDelegate.indicatorSize ||
        offset != oldDelegate.offset ||
        zoom != oldDelegate.zoom ||
        viewportSize != oldDelegate.viewportSize;
  }
}
