import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

class CanvasRulerSnappingPoint extends SnappingPoint with ChangeNotifier {
  double _offset;
  CanvasObjectState? _parent;
  final Axis axis;

  CanvasRulerSnappingPoint({
    required double offset,
    required this.axis,
    CanvasObjectState? parent,
  })  : _offset = offset,
        _parent = parent;

  double get offset => _offset;

  set offset(double value) {
    if (value != _offset) {
      _offset = value;
      notifyListeners();
    }
  }

  @override
  SnappingPoint shift(Offset offset) {
    return CanvasRulerSnappingPoint(
      offset: this.offset + (axis == Axis.horizontal ? offset.dy : offset.dx),
      axis: axis,
      parent: parent,
    );
  }

  CanvasObjectState? get parent => _parent;

  set parent(CanvasObjectState? parent) {
    if (parent != _parent) {
      _parent = parent;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'CanvasRulerSnappingPoint(offset: $offset, axis: $axis)';
  }

  @override
  SnappingResult? computeSnapping(CanvasEditorHandler editor,
      SnappingPoint other, SnappingConfiguration configuration) {
    SnappingResult? result;
    double targetDistance =
        configuration.snappingDistance / editor.transform.zoom;
    Offset target =
        axis == Axis.vertical ? Offset(offset, 0) : Offset(0, offset);
    double angle = axis == Axis.horizontal ? 0 : pi / 2;
    other.visitLines(
      (line) {
        if (line is CanvasRulerSnappingPoint) {
          return true;
        }
        if (line.angle != 0 && !configuration.rotatedSnap) {
          return true;
        }
        if (line.distanceTo(target, angle) <= targetDistance) {
          result = SnappingResult(
            newOffset: line.snapToLine(target),
            angle: axis == Axis.horizontal ? 0 : pi / 2,
          );
          return false;
        }
        return true;
      },
    );
    return result;
  }

  @override
  void visitLines(SnappingLineVisitor visitor) {
    if (axis == Axis.vertical) {
      visitor(SnappingLine(
        point: Offset(
          offset,
          0,
        ),
        angle: 0,
      ));
    } else {
      visitor(SnappingLine(
        point: Offset(
          0,
          offset,
        ),
        angle: pi / 2,
      ));
    }
  }
}

class CanvasRuler extends StatefulWidget {
  final CanvasEditorController controller;
  final CanvasEditorHandler editor;
  final bool showRuler;
  final Widget child;
  final List<CanvasRulerSnappingPoint> snappingPoints;
  final Selection? selection;
  final Matrix4 editorTransform;

  const CanvasRuler({
    super.key,
    required this.controller,
    required this.editor,
    required this.showRuler,
    this.snappingPoints = const [],
    this.selection,
    required this.editorTransform,
    required this.child,
  });

  @override
  State<CanvasRuler> createState() => _CanvasRulerState();
}

class _CanvasRulerState extends State<CanvasRuler> {
  // Axis? _draggingDirection;
  // CanvasRulerSnappingPoint? _draggingPoint;
  RulerSnappingControlSession? _draggingSession;
  // double? _startOffset;
  CanvasRulerSnappingPoint? _hoveredPoint;

  Widget _buildDraggable(double width, Axis direction) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      cursor: _draggingSession != null
          ? SystemMouseCursors.noDrop
          : direction == Axis.horizontal
              ? SystemMouseCursors.resizeUpDown
              : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          setState(() {
            _draggingSession = widget.editor.startControlSession(
                RulerCreateSnappingPointControlSession(
                    widget.editor, direction),
                details.globalPosition);
          });
        },
        onPanUpdate: (details) {
          if (_draggingSession != null) {
            _draggingSession = widget.editor.updateControlSession(
                _draggingSession!, details.globalPosition);
          }
        },
        onPanEnd: (details) {
          if (_draggingSession != null) {
            widget.editor.endControlSession(_draggingSession!);
            _draggingSession = null;
          }
        },
        onPanCancel: () {
          if (_draggingSession != null) {
            widget.editor.cancelControlSession(_draggingSession!);
            _draggingSession = null;
          }
        },
      ),
    );
  }

  Widget _wrapChild(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    if (widget.editor.selectedSnappingPoint != null) {
                      setState(() {
                        widget.editor.selectedSnappingPoint = null;
                      });
                    }
                  },
                ),
              ),
              for (var snappingPoint in widget.snappingPoints)
                _buildSnappingPointDraggable(snappingPoint),
            ],
          );
        });
  }

  Widget _buildSnappingPointDraggable(CanvasRulerSnappingPoint point) {
    var editorTransform = widget.editor.transform;
    return ListenableBuilder(
      listenable: point,
      builder: (context, child) {
        double offset = point.offset * editorTransform.zoom +
            (point.axis == Axis.horizontal
                ? (widget.editor.viewportSize.height /
                        2 *
                        editorTransform.zoom +
                    editorTransform.offset.dy)
                : (widget.editor.viewportSize.width / 2 * editorTransform.zoom +
                    editorTransform.offset.dx));
        return Positioned(
          // 10px to tolerate the hitbox size
          top: point.axis == Axis.horizontal ? offset - 5 : 0,
          left: point.axis == Axis.vertical ? offset - 5 : 0,
          width: point.axis == Axis.horizontal ? null : 10,
          height: point.axis == Axis.vertical ? null : 10,
          bottom: point.axis == Axis.horizontal ? null : 0,
          right: point.axis == Axis.vertical ? null : 0,
          child: child!,
        );
      },
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        cursor: point.axis == Axis.horizontal
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.resizeLeftRight,
        onEnter: (event) {
          setState(() {
            _hoveredPoint = point;
          });
        },
        onExit: (event) {
          setState(() {
            _hoveredPoint = null;
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() {
              widget.editor.selectedSnappingPoint = point;
            });
          },
          onPanStart: (details) {
            setState(() {
              _draggingSession = widget.editor.startControlSession(
                  RulerUpdateSnappingPointControlSession(widget.editor, point),
                  details.globalPosition);
            });
          },
          onPanEnd: (details) {
            if (_draggingSession != null) {
              widget.editor.endControlSession(_draggingSession!);
              _draggingSession = null;
            }
          },
          onPanCancel: () {
            if (_draggingSession != null) {
              widget.editor.cancelControlSession(_draggingSession!);
              _draggingSession = null;
            }
          },
          onPanUpdate: (details) {
            if (_draggingSession != null) {
              _draggingSession = widget.editor.updateControlSession(
                  _draggingSession!, details.globalPosition);
            }
          },
          child: AbsorbPointer(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CanvasTheme.of(context);
    final width = theme.ruler.rulerWidth;
    return MouseRegion(
      opaque: false,
      cursor: _draggingSession?.snappingPoint.axis == Axis.horizontal
          ? SystemMouseCursors.resizeUpDown
          : _draggingSession?.snappingPoint.axis == Axis.vertical
              ? SystemMouseCursors.resizeLeftRight
              : MouseCursor.defer,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (!widget.showRuler)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              bottom: 0,
              child: _wrapChild(context),
            ),
          if (widget.showRuler) ...[
            PositionedDirectional(
              top: width,
              start: width,
              end: 0,
              bottom: 0,
              child: _wrapChild(context),
            ),
            PositionedDirectional(
              top: 0,
              start: width,
              end: 0,
              height: width,
              child: _buildDraggable(width, Axis.horizontal),
            ),
            PositionedDirectional(
              top: width,
              start: 0,
              width: width,
              bottom: 0,
              child: _buildDraggable(width, Axis.vertical),
            )
          ],
          Positioned.fill(
            child: IgnorePointer(
              child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.controller,
                    widget.editor.selectedSnappingPointListenable,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RulerPainter(
                        hovered: _hoveredPoint ??
                            widget.editor.selectedSnappingPoint ??
                            _draggingSession?.snappingPoint,
                        zoom: widget.controller.value.zoom,
                        offset: widget.controller.value.offset,
                        style: theme.ruler.textStyle,
                        strokeWidth: theme.ruler.strokeWidth,
                        backgroundColor: theme.ruler.backgroundColor,
                        strokeColor: theme.ruler.strokeColor,
                        snappingPoints: widget.snappingPoints,
                        rulerWidth: widget.showRuler ? width : 0,
                        strokeHeight: theme.ruler.strokeHeight,
                        textDirection: Directionality.of(context),
                        snapStrokeColor: theme.snap.strokeColor,
                        snapStrokeWidth: theme.snap.strokeWidth,
                        snapTextStyle: theme.snap.textStyle,
                        pixelGridColor: theme.ruler.pixelGridColor,
                        snapSelectedStrokeColor: theme.snap.selectedStrokeColor,
                        selected: widget.editor.selectedSnappingPoint,
                        snapHoveredStrokeColor: theme.snap.hoveredStrokeColor,
                        selection: widget.selection,
                        editorTransform: widget.editorTransform,
                        selectionColor: theme.ruler.selectionColor,
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  static const gaps = <double>[
    1,
    5,
    10,
    25,
    50,
    100,
    250,
    1000,
    2500,
    5000,
    10000,
    25000,
    50000,
    100000,
  ];
  final double zoom;
  final Offset offset;
  final TextStyle style;
  final double strokeWidth;
  final double strokeHeight;
  final Color backgroundColor;
  final Color strokeColor;
  final double rulerWidth;
  final TextDirection textDirection;
  final List<CanvasRulerSnappingPoint> snappingPoints;
  final Color snapStrokeColor;
  final double snapStrokeWidth;
  final TextStyle snapTextStyle;
  final Color pixelGridColor;
  final Color snapSelectedStrokeColor;
  final Color snapHoveredStrokeColor;
  final CanvasRulerSnappingPoint? selected;
  final CanvasRulerSnappingPoint? hovered;
  final Selection? selection;
  final Matrix4 editorTransform;
  final Color selectionColor;

  _RulerPainter({
    required this.zoom,
    required this.offset,
    required this.style,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.strokeColor,
    required this.snappingPoints,
    required this.rulerWidth,
    required this.textDirection,
    required this.strokeHeight,
    required this.snapStrokeColor,
    required this.snapStrokeWidth,
    required this.snapTextStyle,
    required this.pixelGridColor,
    required this.snapSelectedStrokeColor,
    required this.snapHoveredStrokeColor,
    required this.selected,
    required this.hovered,
    required this.selection,
    required this.editorTransform,
    required this.selectionColor,
  }) : super(repaint: Listenable.merge(snappingPoints));

  @override
  void paint(Canvas canvas, Size size) {
    var gap = 100.0;
    // find suitable gap for the current zoom
    int gapIndex;
    for (gapIndex = 0; gapIndex < gaps.length; gapIndex++) {
      if (gaps[gapIndex] * zoom > 50) {
        gap = gaps[gapIndex];
        break;
      }
    }
    Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Size editorSize = Size(size.width - rulerWidth, size.height - rulerWidth);
    Offset rulerOffset =
        Offset(textDirection == TextDirection.ltr ? rulerWidth : 0, rulerWidth);

    bool overrideWithSelection = false;
    Rect? selectionRect;
    if (selection != null && rulerWidth > 0) {
      overrideWithSelection = selection!.singleSelection != null;
      selectionRect = selection!.computeBoundingBox(
        parentTransform: editorTransform,
      );
    }

    if (rulerWidth > 0) {
      // draw the ruler background
      canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, rulerWidth),
        backgroundPaint,
      );
      // vertical (TextDirection adaptive)
      if (textDirection == TextDirection.ltr) {
        canvas.drawRect(
          Rect.fromLTRB(0, 0, rulerWidth, size.height),
          backgroundPaint,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTRB(size.width - rulerWidth, 0, size.width, size.height),
          backgroundPaint,
        );
      }

      // draw the border
      canvas.drawLine(
        Offset(0, rulerWidth),
        Offset(size.width, rulerWidth),
        strokePaint,
      );
      // draw the vertical line
      if (textDirection == TextDirection.ltr) {
        canvas.drawLine(
          Offset(rulerWidth, 0),
          Offset(rulerWidth, size.height),
          strokePaint,
        );
      } else {
        canvas.drawLine(
          Offset(size.width - rulerWidth, 0),
          Offset(size.width - rulerWidth, size.height),
          strokePaint,
        );
      }
      // draw the texts

      double horizontalOffset = (offset.dx + (editorSize.width / 2 * zoom));

      if (overrideWithSelection) {
        print('left: ${selectionRect!.left}');
        horizontalOffset = selectionRect!.left;
      }

      double currentHorizontalText =
          (-horizontalOffset / (gap * zoom)).floorToDouble();
      double currentHorizontalTextOffset =
          rulerOffset.dx + horizontalOffset % (gap * zoom) - gap * zoom;

      while (currentHorizontalTextOffset < (size.width + gap * zoom)) {
        double opacity = 1;
        // if its near to edge (start or end), go invisible, with the range of gap
        double scaledGap = gap * zoom / 4;
        double edgeStart = rulerWidth;
        double edgeEnd = size.width;
        double distanceToEdgeStart = (currentHorizontalTextOffset - edgeStart);
        double distanceToEdgeEnd = (edgeEnd - currentHorizontalTextOffset);
        opacity *= (distanceToEdgeStart.clamp(0, scaledGap) / scaledGap) *
            (distanceToEdgeEnd.clamp(0, scaledGap) / scaledGap);
        if (hovered != null && hovered!.axis == Axis.vertical) {
          scaledGap = gap * zoom;
          double selectedOffset = hovered!.offset * zoom +
              rulerOffset.dx +
              offset.dx +
              editorSize.width / 2 * zoom;
          double distanceToSelected =
              (selectedOffset - currentHorizontalTextOffset).abs();
          double multiplier =
              (distanceToSelected.clamp(0, scaledGap) / scaledGap);
          opacity *= multiplier * multiplier * multiplier;
        }
        if (selectionRect != null) {
          double distanceToStart =
              (selectionRect.left - currentHorizontalTextOffset).abs();
          double distanceToEnd =
              (selectionRect.right - currentHorizontalTextOffset).abs();
          double multiplier =
              (distanceToStart.clamp(0, scaledGap) / scaledGap) *
                  (distanceToEnd.clamp(0, scaledGap) / scaledGap);
          opacity *= multiplier * multiplier * multiplier;
        }
        strokePaint.color = strokeColor.withAlpha((opacity * 255).toInt());
        canvas.drawLine(
          Offset(currentHorizontalTextOffset, rulerWidth),
          Offset(currentHorizontalTextOffset, rulerWidth - strokeHeight),
          strokePaint,
        );
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: (currentHorizontalText * gap).toInt().toString(),
            style: style.copyWith(
              color: style.color?.withAlpha((opacity * 255).toInt()),
            ),
          ),
          textDirection: textDirection,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(currentHorizontalTextOffset - textPainter.width / 2,
              rulerWidth - strokeHeight - textPainter.height),
        );
        textPainter.dispose();
        currentHorizontalText++;
        currentHorizontalTextOffset += gap * zoom;
      }

      // draw the vertical texts
      double verticalOffset = (offset.dy + (editorSize.height / 2 * zoom));

      if (overrideWithSelection) {
        verticalOffset = selectionRect!.top;
      }

      double currentVerticalText =
          (-verticalOffset / (gap * zoom)).floorToDouble();
      double currentVerticalTextOffset =
          rulerOffset.dy + verticalOffset % (gap * zoom) - gap * zoom;
      while (currentVerticalTextOffset < (size.height + gap * zoom)) {
        double opacity = 1;
        double scaledGap = gap * zoom / 4;
        // if its near to edge (start or end), go invisible, with the range of gap
        double edgeStart = rulerWidth;
        double edgeEnd = size.height;
        double distanceToEdgeStart = (currentVerticalTextOffset - edgeStart);
        double distanceToEdgeEnd = (edgeEnd - currentVerticalTextOffset);
        opacity *= (distanceToEdgeStart.clamp(0, scaledGap) / scaledGap) *
            (distanceToEdgeEnd.clamp(0, scaledGap) / scaledGap);
        if (hovered != null && hovered!.axis == Axis.horizontal) {
          scaledGap = gap * zoom;
          double selectedOffset = hovered!.offset * zoom +
              rulerOffset.dy +
              offset.dy +
              editorSize.height / 2 * zoom;
          double distanceToSelected =
              (selectedOffset - currentVerticalTextOffset).abs();
          double multiplier =
              (distanceToSelected.clamp(0, scaledGap) / scaledGap);
          opacity *= multiplier * multiplier;
        }
        if (selectionRect != null) {
          double distanceToStart =
              (selectionRect.top - currentVerticalTextOffset).abs();
          double distanceToEnd =
              (selectionRect.bottom - currentVerticalTextOffset).abs();
          double multiplier =
              (distanceToStart.clamp(0, scaledGap) / scaledGap) *
                  (distanceToEnd.clamp(0, scaledGap) / scaledGap);
          opacity *= multiplier * multiplier * multiplier;
        }
        strokePaint.color = strokeColor.withAlpha((opacity * 255).toInt());
        Offset lineStart = textDirection == TextDirection.ltr
            ? Offset(rulerWidth - strokeHeight, currentVerticalTextOffset)
            : Offset(size.width - rulerWidth, currentVerticalTextOffset);
        canvas.drawLine(
          lineStart,
          Offset(lineStart.dx + strokeHeight, currentVerticalTextOffset),
          strokePaint,
        );
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: (currentVerticalText * gap).toInt().toString(),
            style: style.copyWith(
              color: style.color?.withAlpha((opacity * 255).toInt()),
            ),
          ),
          textDirection: textDirection,
        );
        textPainter.layout();
        // translate to origin
        canvas.save();
        Offset textStart = textDirection == TextDirection.ltr
            ? Offset(rulerWidth - strokeHeight, currentVerticalTextOffset)
            : Offset(size.width - rulerWidth, currentVerticalTextOffset);
        canvas.translate(textStart.dx, textStart.dy);
        canvas.rotate(-pi / 2);
        canvas.translate(-textStart.dx, -textStart.dy);
        // draw the text
        textPainter.paint(
          canvas,
          textStart - Offset(textPainter.width / 2, textPainter.height),
        );
        canvas.restore();
        textPainter.dispose();
        currentVerticalText++;
        currentVerticalTextOffset += gap * zoom;
      }

      if (selectionRect != null) {
        // draw selection rect at top ruler
        var selectionPaint = Paint()
          ..color = selectionColor
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            selectionRect.left + rulerWidth,
            0,
            selectionRect.width,
            rulerWidth,
          ),
          selectionPaint,
        );

        // draw selection rect at left ruler
        canvas.drawRect(
          textDirection == TextDirection.ltr
              ? Rect.fromLTWH(
                  0,
                  selectionRect.top + rulerWidth,
                  rulerWidth,
                  selectionRect.height,
                )
              : Rect.fromLTWH(
                  size.width - rulerWidth,
                  selectionRect.top + rulerWidth,
                  rulerWidth,
                  selectionRect.height,
                ),
          selectionPaint,
        );
      }
      // draw a small box at top left
      canvas.drawRect(
        Rect.fromLTRB(0, 0, rulerWidth, rulerWidth),
        backgroundPaint,
      );
    }

// if gapIndex == 0, it means it maxed out the zoom in, and we should show the pixel grid
    if (gapIndex == 0) {
      // vertical grid
      strokePaint.color = pixelGridColor;
      strokePaint.strokeWidth = 1;
      double currentVerticalOffset = rulerOffset.dy +
          (offset.dy + editorSize.height / 2 * zoom) % (gap * zoom);
      while (currentVerticalOffset < size.height) {
        canvas.drawLine(
          Offset(rulerWidth, currentVerticalOffset),
          Offset(size.width, currentVerticalOffset),
          strokePaint,
        );
        currentVerticalOffset += gap * zoom;
      }
      // horizontal grid
      double currentHorizontalOffset = rulerOffset.dx +
          (offset.dx + editorSize.width / 2 * zoom) % (gap * zoom);
      while (currentHorizontalOffset < size.width) {
        canvas.drawLine(
          Offset(currentHorizontalOffset, rulerWidth),
          Offset(currentHorizontalOffset, size.height),
          strokePaint,
        );
        currentHorizontalOffset += gap * zoom;
      }
    }

    if (rulerWidth > 0) {
      strokePaint.strokeWidth = snapStrokeWidth;
      // draw the snapping points
      for (var snappingPoint in snappingPoints) {
        strokePaint.color = snappingPoint == selected
            ? snapSelectedStrokeColor
            : snappingPoint == hovered
                ? snapHoveredStrokeColor
                : snapStrokeColor;
        double snappingPointOffset = snappingPoint.offset * zoom;
        if (snappingPoint.axis == Axis.vertical) {
          snappingPointOffset +=
              rulerOffset.dx + offset.dx + editorSize.width / 2 * zoom;
          if (textDirection == TextDirection.ltr &&
              snappingPointOffset < rulerOffset.dy) {
            continue;
          }
          if (textDirection == TextDirection.rtl &&
              snappingPointOffset > size.width - rulerOffset.dy) {
            continue;
          }
          if (hovered == snappingPoint) {
            // draw text next to the line
            TextPainter textPainter = TextPainter(
              text: TextSpan(
                text: snappingPoint.offset.toStringAsFixed(0),
                style: snapTextStyle.copyWith(
                  color: snapHoveredStrokeColor,
                ),
              ),
              textDirection: textDirection,
            );
            textPainter.layout();
            textPainter.paint(
                canvas,
                Offset(snappingPointOffset + 8,
                    rulerWidth / 2 - textPainter.height / 2));
            textPainter.dispose();
          }
          canvas.drawLine(
            Offset(snappingPointOffset, 0),
            Offset(snappingPointOffset, size.height),
            strokePaint,
          );
        } else {
          snappingPointOffset +=
              rulerOffset.dy + offset.dy + editorSize.height / 2 * zoom;
          if (snappingPointOffset < rulerOffset.dy) {
            continue;
          }
          if (snappingPointOffset > size.height) {
            continue;
          }
          if (hovered == snappingPoint) {
            // draw text next to the line
            canvas.save();
            TextPainter textPainter = TextPainter(
              text: TextSpan(
                text: snappingPoint.offset.toStringAsFixed(0),
                style: snapTextStyle.copyWith(
                  color: snapHoveredStrokeColor,
                ),
              ),
              textDirection: textDirection,
            );
            textPainter.layout();

            Offset offset = Offset(rulerWidth / 2 - textPainter.width / 2,
                snappingPointOffset - textPainter.height - 8);

            // rotate (origin center text)
            canvas.translate(offset.dx + textPainter.width / 2,
                offset.dy + textPainter.height / 2);
            canvas.rotate(-pi / 2);
            canvas.translate(-offset.dx - textPainter.width / 2,
                -offset.dy - textPainter.height / 2);
            textPainter.paint(canvas, offset);
            textPainter.dispose();
            canvas.restore();
          }
          canvas.drawLine(
            Offset(0, snappingPointOffset),
            Offset(size.width, snappingPointOffset),
            strokePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.style != style ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.snappingPoints != snappingPoints ||
        oldDelegate.rulerWidth != rulerWidth ||
        oldDelegate.zoom != zoom ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.strokeHeight != strokeHeight ||
        oldDelegate.snapStrokeColor != snapStrokeColor ||
        oldDelegate.snapStrokeWidth != snapStrokeWidth ||
        oldDelegate.snapTextStyle != snapTextStyle;
  }
}
