import 'package:canvas/canvas.dart';
import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/material.dart';

class HandleDecoration {
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;

  const HandleDecoration({
    this.color,
    this.borderColor,
    this.borderWidth,
  });
}

class StandardTransformControlThemeData {
  // final Decoration decoration;
  // final Decoration scaleDecoration;
  // final Decoration selectionDecoration;
  final HandleDecoration decoration;
  final HandleDecoration scaleDecoration;
  final HandleDecoration selectionDecoration;

  final Size handleSize;
  final Size rotationHandleSize;

  const StandardTransformControlThemeData({
    required this.decoration,
    required this.scaleDecoration,
    required this.selectionDecoration,
    required this.handleSize,
    required this.rotationHandleSize,
  });

  factory StandardTransformControlThemeData.defaultThemeData() {
    return StandardTransformControlThemeData(
      // decoration: BoxDecoration(
      //   border: Border.all(color: const Color(0xFF198CE8), width: 1),
      //   color: const Color(0xFFFFFFFF),
      // ),
      // scaleDecoration: BoxDecoration(
      //   border: Border.all(color: const Color(0xFF198CE8), width: 1),
      //   color: const Color(0xFF198CE8),
      // ),
      // selectionDecoration: BoxDecoration(
      //   border: Border.all(color: const Color(0xFF198CE8), width: 1),
      //   color: const Color(0x00000000),
      // ),
      decoration: HandleDecoration(
        color: const Color(0xFFFFFFFF),
        borderColor: const Color(0xFF198CE8),
        borderWidth: 1,
      ),
      scaleDecoration: HandleDecoration(
        color: const Color(0xFF198CE8),
        borderColor: const Color(0xFF198CE8),
        borderWidth: 1,
      ),
      selectionDecoration: HandleDecoration(
        borderColor: const Color(0xFF198CE8),
        borderWidth: 1,
      ),
      handleSize: const Size(8, 8),
      rotationHandleSize: const Size(10, 10),
    );
  }
}

class StandardTransformControl extends TransformControl {
  const StandardTransformControl();
  @override
  Widget build(BuildContext context, CanvasItem item, bool canTransform) {
    return StandardTransformControlWidget(
        item: item, canTransform: canTransform);
  }
}

class StandardTransformControlWidget extends StatefulWidget {
  final CanvasItem item;
  final Matrix4? parentTransform;
  final bool canTransform;

  const StandardTransformControlWidget({
    super.key,
    required this.item,
    this.parentTransform,
    required this.canTransform,
  });

  @override
  State<StandardTransformControlWidget> createState() =>
      _StandardTransformControlWidgetState();
}

class DragSession {
  final CanvasItem item;
  final ItemConstraints startLayout;
  final Offset startOffset;
  final LayoutSnapping snapping;
  final TransformSession transformSession;
  final VoidCallback onUpdate;

  Offset totalOffset = Offset.zero;

  DragSession({
    required this.item,
    required this.startOffset,
    required this.snapping,
    required this.transformSession,
    required this.onUpdate,
  }) : startLayout = item.constraints;
}

class RotateDragSession extends DragSession {
  final double startRotation;

  double totalRotationDelta = 0;

  RotateDragSession({
    required super.item,
    required super.startOffset,
    required super.snapping,
    required super.transformSession,
    required super.onUpdate,
    required this.startRotation,
  });
}

class _StandardTransformControlWidgetState
    extends State<StandardTransformControlWidget> with CanvasElementDragger {
  late StandardTransformControlThemeData theme;
  late CanvasViewportData viewportData;
  // Offset? _totalOffset;
  // TransformSession? _session;
  // double? _startRotation;
  // VoidCallback? _onUpdate;
  // CanvasItem? _startNode;
  // ItemConstraints? _startLayout;
  // LayoutSnapping? _snapping;

  DragSession? _dragSession;

  CanvasItem _findSelected() {
    CanvasItem? current = widget.item;
    while (current != null) {
      var parent = current.parent;
      if (parent != null && !parent.selected) {
        break;
      }
      current = parent;
    }
    return current ?? widget.item;
  }

  @override
  void handleDragAdjustment(Offset delta) {
    // if (_totalOffset != null && _onUpdate != null) {
    //   _totalOffset =
    //       (_totalOffset! - delta / viewportData.handle.transform.zoom);
    //   _onUpdate!();
    //   viewportData.handle.drag(delta);
    // }
    if (_dragSession != null) {
      _dragSession!.totalOffset = _dragSession!.totalOffset - delta;
      _dragSession!.onUpdate();
      viewportData.handle.drag(delta);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = StandardTransformControlThemeData.defaultThemeData();
    viewportData = CanvasViewportData.of(context);
    if (_dragSession != null) {
      VoidCallback onUpdate = _dragSession!.onUpdate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onUpdate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double viewportZoom = viewportData.handle.transform.zoom;
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.item.selectedNotifier,
        widget.item.transformListenable,
        viewportData.handle.focusedItemListenable,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
                child: IgnorePointer(child: _buildBoundingBox(context))),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  widget.item.childrenListenable,
                  viewportData.handle.focusedItemListenable,
                ]),
                builder: (context, child) {
                  return GroupWidget(
                    children: [
                      for (final child in widget.item.children)
                        StandardTransformControlWidget(
                          item: child,
                          canTransform: !(viewportData.handle.focusedItem
                                  ?.isDescendant(child) ??
                              false),
                          parentTransform: widget.parentTransform == null
                              ? widget.item.transform.toMatrix4()
                              : widget.parentTransform! *
                                  widget.item.transform.toMatrix4(),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (widget.item.selected &&
                widget.item.opaque &&
                widget.canTransform)
              ..._buildHandleControls(context).map((e) {
                return Positioned.fill(child: e);
              }),
          ],
        );
      },
    );
    return ListenableBuilder(
      listenable: Listenable.merge({
        widget.item.selectedNotifier,
        widget.item.transformListenable,
        viewportData.handle.focusedItemListenable,
      }),
      builder: (context, child) {
        var controlOffset = widget.item.transform.offset * viewportZoom;
        return Transform.translate(
          offset: controlOffset,
          child: Transform.rotate(
            angle: widget.item.transform.rotation,
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scaleX: widget.item.transform.scale.dx,
              scaleY: widget.item.transform.scale.dy,
              alignment: Alignment.topLeft,
              child: GroupWidget(
                children: [
                  if (widget.item is! RootCanvasItem) _buildSelection(context),
                  ListenableBuilder(
                    listenable: Listenable.merge({
                      widget.item.childrenListenable,
                      viewportData.handle.focusedItemListenable,
                    }),
                    builder: (context, child) {
                      return GroupWidget(
                        children: [
                          for (final child in widget.item.children)
                            StandardTransformControlWidget(
                              item: child,
                              // canTransform: !child.contentFocused,
                              // TODO: Fix this
                              canTransform: !(viewportData.handle.focusedItem
                                      ?.isDescendant(child) ??
                                  false),
                              parentTransform: widget.parentTransform == null
                                  ? widget.item.transform
                                  : widget.parentTransform! *
                                      widget.item.transform,
                            ),
                        ],
                      );
                    },
                  ),
                  if (widget.item.selected &&
                      widget.item.opaque &&
                      widget.canTransform)
                    ..._buildControls(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wrapWithPanHandler({
    required Widget child,
    required void Function(TransformNode node, Offset delta,
            {LayoutSnapping? snapping})
        visitor,
    required Offset? Function(LayoutSnapping snapping) snapping,
    String? debugName,
  }) {
    double viewportZoom = viewportData.handle.transform.zoom;
    return PanGesture(
      behavior: HitTestBehavior.deferToChild,
      onPanStart: (details) {
        _dragSession = DragSession(
          item: _findSelected(),
          startOffset: details.localPosition,
          snapping: viewportData.handle.createLayoutSnapping(
            (details) {
              return !details.selected;
            },
          ),
          transformSession: viewportData.handle.beginTransform(),
          onUpdate: () {
            var dragSession = _dragSession!;
            TransformNode node = TransformNode(
              dragSession.item,
              // _startNode!.transform,
              dragSession.item.transform,
              null,
              // _startLayout!,
              dragSession.startLayout,
            );
            var deltaOffset = dragSession.totalOffset;
            visitor(
              node,
              handleDeltaTransform(deltaOffset, dragSession.item),
              snapping: dragSession.snapping,
            );
            node.apply(node.constraint);
            dragSession.transformSession.visit(
              (node) {
                if (node.item == dragSession.item) {
                  return;
                }
                visitor(node, snapping(dragSession.snapping) ?? deltaOffset);
                node.apply(node.constraint);
              },
            );
            dragSession.transformSession.apply();
          },
        );
        viewportData.handle.startDraggingSession(this);
      },
      onPanUpdate: (details) {
        Offset delta = details.delta;
        var dragSession = _dragSession!;
        dragSession.totalOffset =
            dragSession.totalOffset + delta / viewportZoom;
        dragSession.onUpdate();
      },
      onPanEnd: (_) {
        _dragSession = null;
        viewportData.handle.endDraggingSession(this);
      },
      onPanCancel: () {
        if (_dragSession != null) {
          _dragSession!.transformSession.reset();
          _dragSession = null;
        }
        viewportData.handle.endDraggingSession(this);
      },
      child: child,
    );
  }

  Widget _wrapWithRotationHandler({
    required Widget child,
    required Alignment alignment,
  }) {
    double viewportZoom = viewportData.handle.transform.zoom;
    Size scaledSize = widget.item.transform.size * viewportZoom;
    Offset origin = !viewportData.anchoredRotate
        ? Offset(scaledSize.width / 2, scaledSize.height / 2)
        : (alignment * -1).alongSize(scaledSize);
    return PanGesture(
      behavior: HitTestBehavior.deferToChild,
      onPanStart: (details) {
        var localPosition =
            alignment.alongSize(scaledSize) + details.localPosition;
        var diff = origin - localPosition;
        var angle = diff.direction;
        _dragSession = RotateDragSession(
          item: _findSelected(),
          startOffset: details.localPosition,
          snapping: viewportData.handle.createLayoutSnapping(
            (details) {
              return !details.selected;
            },
          ),
          transformSession: viewportData.handle.beginTransform(),
          onUpdate: () {
            var dragSession = _dragSession as RotateDragSession;
            TransformNode node = TransformNode(
              dragSession.item,
              dragSession.item.transform,
              null,
              dragSession.startLayout,
            );
            var deltaAngle = dragSession.totalRotationDelta;
            node.newConstraint = node.constraint.rotate(
              node.item,
              deltaAngle,
              alignment: !viewportData.anchoredRotate
                  ? Alignment.center
                  : alignment * -1,
              snapping: dragSession.snapping,
            );
            node.apply(node.constraint);
            dragSession.transformSession.visit(
              (node) {
                if (node.item == dragSession.item) {
                  return;
                }
                node.newConstraint = node.constraint.rotate(
                  node.item,
                  deltaAngle,
                  alignment: !viewportData.anchoredRotate
                      ? Alignment.center
                      : alignment * -1,
                  snapping: dragSession.snapping,
                );
                node.apply(node.constraint);
              },
            );
            dragSession.transformSession.apply();
          },
          startRotation: angle,
        );
      },
      onPanUpdate: (details) {
        var dragSession = _dragSession as RotateDragSession;
        var localPosition =
            alignment.alongSize(scaledSize) + details.localPosition;
        var diff = origin - localPosition;
        var angle = diff.direction;
        var delta = angle - dragSession.startRotation;
        dragSession.totalRotationDelta = delta;
        dragSession.onUpdate();
      },
      onPanEnd: (details) {
        _dragSession = null;
      },
      onPanCancel: () {
        var dragSession = _dragSession as RotateDragSession?;
        if (dragSession != null) {
          dragSession.transformSession.reset();
          _dragSession = null;
        }
      },
      child: child,
    );
  }

  bool get _isScaling => viewportData.resizeMode == ResizeMode.scale;

  Rect _inflateRect(Rect rect, Offset size) {
    return Rect.fromLTWH(
      rect.left - size.dx,
      rect.top - size.dy,
      rect.width + size.dx * 2,
      rect.height + size.dy * 2,
    );
  }

  List<Widget> _buildControls(BuildContext context) {
    var parentTransform = widget.parentTransform;
    var controlHandleSize = theme.handleSize;
    var controlRotationSize = theme.rotationHandleSize;
    // if (parentTransform != null) {
    //   controlHandleSize = Size(
    //     controlHandleSize.width / parentTransform.scale.dx,
    //     controlHandleSize.height / parentTransform.scale.dy,
    //   );
    //   controlRotationSize = Size(
    //     controlRotationSize.width / parentTransform.scale.dx,
    //     controlRotationSize.height / parentTransform.scale.dy,
    //   );
    // }
    // divide by item scale
    controlRotationSize = Size(
      controlRotationSize.width / widget.item.transform.scale.dx,
      controlRotationSize.height / widget.item.transform.scale.dy,
    );
    controlHandleSize = Size(
      controlHandleSize.width / widget.item.transform.scale.dx,
      controlHandleSize.height / widget.item.transform.scale.dy,
    );
    double globalRotation = widget.item.transform.rotation;
    // if (parentTransform != null) {
    //   globalRotation += parentTransform.rotation;
    // }
    double viewportZoom = viewportData.handle.transform.zoom;

    Offset halfSize =
        Offset(controlHandleSize.width / 2, controlHandleSize.height / 2);
    Offset handleSize =
        Offset(controlHandleSize.width, controlHandleSize.height);

    Offset sizeRotation =
        Offset(controlRotationSize.width, controlRotationSize.height);
    Offset halfRotationSize = sizeRotation / 2;
    Size size = widget.item.transform.size * viewportZoom;
    Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    Rect rotationBounds = _inflateRect(bounds, halfSize);
    Offset topLeft = bounds.topLeft - halfSize;
    Offset topRight = bounds.topRight - halfSize;
    Offset bottomLeft = bounds.bottomLeft - halfSize;
    Offset bottomRight = bounds.bottomRight - halfSize;
    Offset rotationTopLeft = rotationBounds.topLeft - halfRotationSize;
    Offset rotationTopRight = rotationBounds.topRight - halfRotationSize;
    Offset rotationBottomLeft = rotationBounds.bottomLeft - halfRotationSize;
    Offset rotationBottomRight = rotationBounds.bottomRight - halfRotationSize;
    Offset top = Offset(bounds.left + halfSize.dx, bounds.top - halfSize.dy);
    Offset right = Offset(bounds.right - halfSize.dx, bounds.top + halfSize.dy);
    Offset bottom =
        Offset(bounds.left + halfSize.dx, bounds.bottom - halfSize.dy);
    Offset left = Offset(bounds.left - halfSize.dx, bounds.top + halfSize.dy);
    bool flipX = size.width < 0;
    bool flipY = size.height < 0;
    double horizontalLength = bounds.width - handleSize.dx;
    double verticalLength = bounds.height - handleSize.dy;
    if (horizontalLength < 0) {
      top = top.translate(horizontalLength, 0);
      bottom = bottom.translate(horizontalLength, 0);
      horizontalLength = horizontalLength.abs();
    }
    if (verticalLength < 0) {
      left = left.translate(0, verticalLength);
      right = right.translate(0, verticalLength);
      verticalLength = verticalLength.abs();
    }
    return [
      // top left rotation
      Transform.translate(
        offset: rotationTopLeft,
        child: MouseRegion(
          cursor: ResizeCursor.bottomLeft
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithRotationHandler(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: controlRotationSize.width,
              height: controlRotationSize.height,
            ),
          ),
        ),
      ),
      // top right rotation
      Transform.translate(
        offset: rotationTopRight,
        child: MouseRegion(
          cursor: ResizeCursor.bottomRight
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithRotationHandler(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: controlRotationSize.width,
              height: controlRotationSize.height,
            ),
          ),
        ),
      ),
      // bottom right rotation
      Transform.translate(
        offset: rotationBottomRight,
        child: MouseRegion(
          cursor: ResizeCursor.topRight
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithRotationHandler(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: controlRotationSize.width,
              height: controlRotationSize.height,
            ),
          ),
        ),
      ),
      // bottom left rotation
      Transform.translate(
        offset: rotationBottomLeft,
        child: MouseRegion(
          cursor:
              ResizeCursor.topLeft.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithRotationHandler(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: controlRotationSize.width,
              height: controlRotationSize.height,
            ),
          ),
        ),
      ),
      // top
      Transform.translate(
        offset: top,
        child: MouseRegion(
          cursor: ResizeCursor.top.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'top',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleTop(
                  node.item,
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeTop(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: horizontalLength,
              height: controlHandleSize.height,
            ),
          ),
        ),
      ),
      // right
      Transform.translate(
        offset: right,
        child: MouseRegion(
          cursor:
              ResizeCursor.right.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'right',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleRight(
                  node.item,
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeRight(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: controlHandleSize.width,
              height: verticalLength,
            ),
          ),
        ),
      ),
      // bottom
      Transform.translate(
        offset: bottom,
        child: MouseRegion(
          cursor:
              ResizeCursor.bottom.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'bottom',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleBottom(
                  node.item,
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeBottom(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: horizontalLength,
              height: controlHandleSize.height,
            ),
          ),
        ),
      ),
      // left
      Transform.translate(
        offset: left,
        child: MouseRegion(
          cursor:
              ResizeCursor.left.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'left',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleLeft(
                  node.item,
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeLeft(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: controlHandleSize.width,
              height: verticalLength,
            ),
          ),
        ),
      ),
      // top left
      Transform.translate(
        offset: topLeft,
        child: MouseRegion(
          cursor:
              ResizeCursor.topLeft.getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'top left',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleTopLeft(
                  node.item,
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeTopLeft(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: controlHandleSize.width,
              height: controlHandleSize.height,
              // decoration:
              //     !_isScaling ? theme.decoration : theme.scaleDecoration,
            ),
          ),
        ),
      ),
      // top right
      Transform.translate(
        offset: topRight,
        child: MouseRegion(
          cursor: ResizeCursor.topRight
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'top right',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleTopRight(
                  node.item,
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeTopRight(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: controlHandleSize.width,
              height: controlHandleSize.height,
              // decoration:
              //     !_isScaling ? theme.decoration : theme.scaleDecoration,
            ),
          ),
        ),
      ),
      // bottom left
      Transform.translate(
        offset: bottomLeft,
        child: MouseRegion(
          cursor: ResizeCursor.bottomLeft
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'bottom left',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleBottomLeft(
                  node.item,
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeBottomLeft(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: controlHandleSize.width,
              height: controlHandleSize.height,
              // decoration:
              //     !_isScaling ? theme.decoration : theme.scaleDecoration,
            ),
          ),
        ),
      ),
      // bottom right
      Transform.translate(
        offset: bottomRight,
        child: MouseRegion(
          cursor: ResizeCursor.bottomRight
              .getMouseCursor(globalRotation, flipX, flipY),
          child: _wrapWithPanHandler(
            debugName: 'bottom right',
            visitor: (node, delta, {LayoutSnapping? snapping}) {
              if (_isScaling) {
                node.newConstraint = node.constraint.rescaleBottomRight(
                  node.item,
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newConstraint = node.constraint.resizeBottomRight(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: controlHandleSize.width,
              height: controlHandleSize.height,
              // decoration:
              //     !_isScaling ? theme.decoration : theme.scaleDecoration,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSelection(BuildContext context) {
    Size size = widget.item.transform.size * viewportData.handle.transform.zoom;
    Offset flipOffset = Offset(
      size.width < 0 ? size.width : 0,
      size.height < 0 ? size.height : 0,
    );
    size = size.abs();
    return Transform.translate(
      offset: flipOffset,
      child: IgnorePointer(
        child: SizedBox.fromSize(
          size: size,
          child: Builder(builder: (context) {
            return Container(
                // decoration: viewportData.handle.hoveredItem == widget.item ||
                //         widget.item.selected
                //     ? theme.selectionDecoration
                //     : null,
                );
          }),
        ),
      ),
    );
  }

  Widget _buildBoundingBox(BuildContext context) {
    return _buildHandle(
      size: widget.item.transform.size,
      shouldScaleX: true,
      shouldScaleY: true,
      alignment: Alignment.topLeft,
      selfAlignment: Alignment.topLeft,
      borderColor: theme.selectionDecoration.borderColor,
      color: theme.selectionDecoration.color,
      strokeWidth: theme.selectionDecoration.borderWidth,
    );
  }

  List<Widget> _buildHandleControls(BuildContext context) {
    double widthDiff = theme.handleSize.width - theme.rotationHandleSize.width;
    double heightDiff =
        theme.handleSize.height - theme.rotationHandleSize.height;
    double horizontalMargin = theme.handleSize.width - widthDiff;
    double verticalMargin = theme.handleSize.height - heightDiff;
    bool flipX = widget.item.transform.size.width < 0;
    bool flipY = widget.item.transform.size.height < 0;
    var decoration = viewportData.resizeMode == ResizeMode.resize
        ? theme.decoration
        : theme.scaleDecoration;
    return [
      // top resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        opaque: false,
        cursor: ResizeCursor.top.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'top',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleTop(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeTop(
              node.item,
              delta,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size:
                Size(widget.item.transform.size.width, theme.handleSize.height),
            shouldScaleX: true,
            alignment: Alignment.topCenter,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // right resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        opaque: false,
        cursor: ResizeCursor.right.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'right',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleRight(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeRight(
              node.item,
              delta,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size:
                Size(theme.handleSize.width, widget.item.transform.size.height),
            shouldScaleY: true,
            alignment: Alignment.centerRight,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // bottom resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        opaque: false,
        cursor: ResizeCursor.bottom.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'bottom',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleBottom(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeBottom(
              node.item,
              delta,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size:
                Size(widget.item.transform.size.width, theme.handleSize.height),
            shouldScaleX: true,
            alignment: Alignment.bottomCenter,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // left resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        opaque: false,
        cursor: ResizeCursor.left.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'left',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleLeft(
                node.item,
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeLeft(
              node.item,
              delta,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size:
                Size(theme.handleSize.width, widget.item.transform.size.height),
            shouldScaleY: true,
            alignment: Alignment.centerLeft,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // top left resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        opaque: false,
        cursor: ResizeCursor.topLeft.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'top left',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleTopLeft(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeTopLeft(
              node.item,
              delta,
              proportional: viewportData.proportionalResize,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size: theme.handleSize,
            alignment: Alignment.topLeft,
            selfAlignment: Alignment.center,
            borderColor: decoration.borderColor,
            color: decoration.color,
            strokeWidth: decoration.borderWidth,
          ),
        ),
      ),
      // top right resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.topRight.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'top right',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleTopRight(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeTopRight(
              node.item,
              delta,
              proportional: viewportData.proportionalResize,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size: theme.handleSize,
            alignment: Alignment.topRight,
            selfAlignment: Alignment.center,
            borderColor: decoration.borderColor,
            color: decoration.color,
            strokeWidth: decoration.borderWidth,
          ),
        ),
      ),
      // bottom right resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.bottomRight.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'bottom right',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleBottomRight(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeBottomRight(
              node.item,
              delta,
              proportional: viewportData.proportionalResize,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size: theme.handleSize,
            alignment: Alignment.bottomRight,
            selfAlignment: Alignment.center,
            borderColor: decoration.borderColor,
            color: decoration.color,
            strokeWidth: decoration.borderWidth,
          ),
        ),
      ),
      // bottom left resize
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.bottomLeft.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithPanHandler(
          debugName: 'bottom left',
          visitor: (node, delta, {LayoutSnapping? snapping}) {
            if (_isScaling) {
              node.newConstraint = node.constraint.rescaleBottomLeft(
                node.item,
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
              return;
            }
            node.newConstraint = node.constraint.resizeBottomLeft(
              node.item,
              delta,
              proportional: viewportData.proportionalResize,
              symmetric: viewportData.symmetricResize,
              snapping: snapping,
            );
          },
          snapping: (snapping) =>
              _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
          child: _buildHandle(
            size: theme.handleSize,
            alignment: Alignment.bottomLeft,
            selfAlignment: Alignment.center,
            borderColor: decoration.borderColor,
            color: decoration.color,
            strokeWidth: decoration.borderWidth,
          ),
        ),
      ),
      // top left rotation
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.bottomLeft.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithRotationHandler(
          alignment: Alignment.topLeft,
          child: _buildHandle(
            size: theme.rotationHandleSize,
            margin: EdgeInsets.symmetric(
              horizontal: horizontalMargin,
              vertical: verticalMargin,
            ),
            alignment: Alignment.topLeft,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // top right rotation
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.bottomRight.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithRotationHandler(
          alignment: Alignment.topRight,
          child: _buildHandle(
            size: theme.rotationHandleSize,
            margin: EdgeInsets.symmetric(
              horizontal: -horizontalMargin,
              vertical: verticalMargin,
            ),
            alignment: Alignment.topRight,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // bottom right rotation
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.topRight.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _wrapWithRotationHandler(
          alignment: Alignment.bottomRight,
          child: _buildHandle(
            size: theme.rotationHandleSize,
            margin: EdgeInsets.symmetric(
              horizontal: -horizontalMargin,
              vertical: -verticalMargin,
            ),
            alignment: Alignment.bottomRight,
            selfAlignment: Alignment.center,
          ),
        ),
      ),
      // bottom left rotation
      MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: ResizeCursor.topLeft.getMouseCursor(
          widget.item.transform.rotation,
          flipX,
          flipY,
        ),
        child: _buildHandle(
          size: theme.rotationHandleSize,
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: -verticalMargin,
          ),
          alignment: Alignment.bottomLeft,
          selfAlignment: Alignment.center,
        ),
      ),
    ];
  }

  Widget _buildHandle({
    required Size size,
    required Alignment alignment,
    required Alignment selfAlignment,
    bool shouldScaleX = false,
    bool shouldScaleY = false,
    Color? borderColor,
    double? strokeWidth,
    Color? color,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    double viewportZoom = viewportData.handle.transform.zoom;
    LayoutTransform canvasTransform = LayoutTransform(
      offset: viewportData.handle.canvasOffset,
      scale: Offset(viewportZoom, viewportZoom),
    );
    return CustomPaint(
      painter: BoundingBoxPainter(
        shouldScaleX: shouldScaleX,
        shouldScaleY: shouldScaleY,
        // globalTransform: canvasTransform *
        //     (widget.parentTransform != null
        //         ? widget.parentTransform! * widget.item.transform
        //         : widget.item.transform),
        globalTransform: canvasTransform.toMatrix4() *
            (widget.parentTransform != null
                ? widget.parentTransform! * widget.item.transform.toMatrix4()
                : widget.item.transform.toMatrix4()),
        selfAlignment: selfAlignment,
        itemSize: widget.item.transform.size,
        size: size,
        alignment: alignment,
        borderColor: borderColor,
        strokeWidth: strokeWidth,
        color: color,
        margin: margin,
      ),
    );
  }
}
