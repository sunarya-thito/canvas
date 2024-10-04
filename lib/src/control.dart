import 'package:canvas/canvas.dart';
import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/material.dart';

class StandardTransformControlThemeData {
  final Decoration decoration;
  final Decoration scaleDecoration;
  final Decoration selectionDecoration;

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
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF198CE8), width: 1),
        color: const Color(0xFFFFFFFF),
      ),
      scaleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF198CE8), width: 1),
        color: const Color(0xFF198CE8),
      ),
      selectionDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF198CE8), width: 1),
        color: const Color(0x00000000),
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
  final LayoutTransform? parentTransform;
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

class _StandardTransformControlWidgetState
    extends State<StandardTransformControlWidget> with CanvasElementDragger {
  late StandardTransformControlThemeData theme;
  late CanvasViewportData viewportData;
  Offset? _totalOffset;
  TransformSession? _session;
  double? _startRotation;
  VoidCallback? _onUpdate;
  CanvasItem? _startNode;
  Layout? _startLayout;
  LayoutSnapping? _snapping;

  double get globalRotation {
    double rotation = widget.item.transform.rotation;
    if (widget.parentTransform != null) {
      rotation += widget.parentTransform!.rotation;
    }
    return rotation;
  }

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
    if (_totalOffset != null && _onUpdate != null) {
      _totalOffset = _totalOffset! - delta / viewportData.handle.transform.zoom;
      _onUpdate!();
      viewportData.handle.drag(delta);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = StandardTransformControlThemeData.defaultThemeData();
    viewportData = CanvasViewportData.of(context);
    if (_onUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_onUpdate != null) {
          _onUpdate!();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double viewportZoom = viewportData.handle.transform.zoom;
    return ListenableBuilder(
      listenable: Listenable.merge({
        widget.item.selectedNotifier,
        widget.item.layoutListenable,
        viewportData.handle.focusedItemListenable,
      }),
      builder: (context, child) {
        return Transform.translate(
          offset: widget.item.transform.offset * viewportZoom,
          child: Transform.rotate(
            angle: widget.item.transform.rotation,
            alignment: Alignment.topLeft,
            child: GroupWidget(
              children: [
                if (widget.item is! RootCanvasItem) _buildSelection(context),
                ListenableBuilder(
                  listenable: widget.item.childrenListenable,
                  builder: (context, child) {
                    return GroupWidget(
                      children: [
                        for (final child in widget.item.children)
                          StandardTransformControlWidget(
                            item: child,
                            // canTransform: !child.contentFocused,
                            // TODO: Fix this
                            canTransform: true,
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
        );
      },
    );
  }

  Widget _wrapWithPanHandler({
    required Widget child,
    required void Function(TransformNode node, Offset delta, {LayoutSnapping? snapping}) visitor,
    required Offset? Function(LayoutSnapping snapping) snapping,
    String? debugName,
  }) {
    double viewportZoom = viewportData.handle.transform.zoom;
    return PanGesture(
      onPanStart: (details) {
        _totalOffset = Offset.zero;
        _session = viewportData.handle.beginTransform();
        _startNode = _findSelected();
        _startLayout = _startNode!.layout;
        _snapping = LayoutSnapping(viewportData.handle.snappingConfiguration,
            _startNode!, _startNode!.parentTransform);
        viewportData.handle.fillInSnappingPoints(_snapping!);
        viewportData.handle.startDraggingSession(this);
      },
      onPanUpdate: (details) {
        Offset delta = details.delta;
        _totalOffset = _totalOffset! + delta / viewportZoom;
        void update() {
          _session!.reset();
          TransformNode node = TransformNode(
            _startNode!,
            _startNode!.transform,
            null,
            _startLayout!,
          );
          visitor(
            node,
            _totalOffset!,
            snapping: _snapping,
          );
          node.apply(node.layout);
          _session!.visit(
            (node) {
              if (node.item == _startNode) {
                return;
              }
              visitor(node, snapping(_snapping!) ?? _totalOffset!);
              node.apply(node.layout);
            },
          );
        }

        _onUpdate = update;
        update();
      },
      onPanEnd: (_) {
        _totalOffset = null;
        _onUpdate = null;
        _session = null;
        _startNode = null;
        _startLayout = null;
        viewportData.handle.endDraggingSession(this);
      },
      onPanCancel: () {
        if (_session != null) {
          _session!.reset();
        }
        _totalOffset = null;
        _session = null;
        _onUpdate = null;
        _startNode = null;
        _startLayout = null;
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
    Size scaledSize = widget.item.transform.scaledSize * viewportZoom;
    Offset origin = !viewportData.anchoredRotate
        ? Offset(scaledSize.width / 2, scaledSize.height / 2)
        : (alignment * -1).alongSize(scaledSize);
    return PanGesture(
      onPanStart: (details) {
        var localPosition =
            alignment.alongSize(scaledSize) + details.localPosition;
        var diff = origin - localPosition;
        var angle = diff.direction;
        _startRotation = angle;
        _session = viewportData.handle.beginTransform();
        _startNode = _findSelected();
        _startLayout = _startNode!.layout;
        _snapping = LayoutSnapping(
            viewportData.snapping, _startNode!, _startNode!.parentTransform);
        viewportData.handle.fillInSnappingPoints(_snapping!);
      },
      onPanUpdate: (details) {
        void update() {
          var localPosition =
              alignment.alongSize(scaledSize) + details.localPosition;
          var diff = origin - localPosition;
          var angle = diff.direction;
          var delta = angle - _startRotation!;
          _startNode!.layout = _startLayout!.rotate(
            delta,
            alignment: !viewportData.anchoredRotate
                ? Alignment.center
                : alignment * -1,
            snapping: _snapping,
          );
          _session!.visit(
            (node) {
              if (_startNode!.isDescendantOf(node.item)) {
                return;
              }
              node.newLayout = node.layout.rotate(
                  _snapping?.newRotationDelta ?? delta,
                  alignment: !viewportData.anchoredRotate
                      ? Alignment.center
                      : alignment * -1);
            },
          );
          _session!.apply();
        }

        _onUpdate = update;
        update();
      },
      onPanEnd: (details) {
        _startRotation = null;
        _session = null;
        _startLayout = null;
        _startNode = null;
        _onUpdate = null;
      },
      onPanCancel: () {
        if (_session != null) {
          _session!.reset();
        }
        _onUpdate = null;
        _startRotation = null;
        _startLayout = null;
        _startNode = null;
        _session = null;
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
    double viewportZoom = viewportData.handle.transform.zoom;
    Offset halfSize =
        Offset(theme.handleSize.width / 2, theme.handleSize.height / 2);
    Offset handleSize = Offset(theme.handleSize.width, theme.handleSize.height);
    Offset sizeRotation =
        Offset(theme.rotationHandleSize.width, theme.rotationHandleSize.height);
    Offset halfRotationSize = sizeRotation / 2;
    Size size = widget.item.transform.scaledSize * viewportZoom;
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
              width: theme.rotationHandleSize.width,
              height: theme.rotationHandleSize.height,
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
              width: theme.rotationHandleSize.width,
              height: theme.rotationHandleSize.height,
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
              width: theme.rotationHandleSize.width,
              height: theme.rotationHandleSize.height,
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
              width: theme.rotationHandleSize.width,
              height: theme.rotationHandleSize.height,
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
                node.newLayout = node.layout.rescaleTop(
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeTop(
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: horizontalLength,
              height: theme.handleSize.height,
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
                node.newLayout = node.layout.rescaleRight(
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeRight(
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: theme.handleSize.width,
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
                node.newLayout = node.layout.rescaleBottom(
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottom(
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: horizontalLength,
              height: theme.handleSize.height,
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
                node.newLayout = node.layout.rescaleLeft(
                  delta,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeLeft(
                delta,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: SizedBox(
              width: theme.handleSize.width,
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
                node.newLayout = node.layout.rescaleTopLeft(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeTopLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration:
                  !_isScaling ? theme.decoration : theme.scaleDecoration,
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
                node.newLayout = node.layout.rescaleTopRight(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeTopRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration:
                  !_isScaling ? theme.decoration : theme.scaleDecoration,
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
                node.newLayout = node.layout.rescaleBottomLeft(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottomLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration:
                  !_isScaling ? theme.decoration : theme.scaleDecoration,
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
                node.newLayout = node.layout.rescaleBottomRight(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                  snapping: snapping,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottomRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
                snapping: snapping,
              );
            },
            snapping: (snapping) =>
                _isScaling ? snapping.newScaleDelta : snapping.newSizeDelta,
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration:
                  !_isScaling ? theme.decoration : theme.scaleDecoration,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSelection(BuildContext context) {
    Size size =
        widget.item.transform.scaledSize * viewportData.handle.transform.zoom;
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
              decoration: viewportData.handle.hoveredItem == widget.item ||
                      widget.item.selected
                  ? theme.selectionDecoration
                  : null,
            );
          }),
        ),
      ),
    );
  }
}
