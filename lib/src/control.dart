import 'package:canvas/canvas.dart';
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
  Widget build(BuildContext context, CanvasItemNode node) {
    return StandardTransformControlWidget(item: node.item, node: node);
  }
}

class StandardTransformControlWidget extends StatefulWidget {
  final CanvasItemNode node;
  final CanvasItem item;
  final LayoutTransform? parentTransform;

  const StandardTransformControlWidget({
    super.key,
    required this.item,
    required this.node,
    this.parentTransform,
  });

  @override
  State<StandardTransformControlWidget> createState() =>
      _StandardTransformControlWidgetState();
}

class _StandardTransformControlWidgetState
    extends State<StandardTransformControlWidget> {
  bool _hover = false;

  late StandardTransformControlThemeData theme;
  late CanvasViewportData viewportData;
  Offset? _totalOffset;
  TransformSession? _session;
  double? _startRotation;
  VoidCallback? _onUpdate;
  CanvasItemNode? _startNode;
  Layout? _startLayout;
  LayoutSnapping? _snapping;

  double get globalRotation {
    double rotation = widget.item.transform.rotation;
    if (widget.parentTransform != null) {
      rotation += widget.parentTransform!.rotation;
    }
    return rotation;
  }

  CanvasItemNode _findSelected() {
    CanvasItemNode? current = widget.node;
    while (current != null) {
      var parent = current.parent;
      if (parent != null && !parent.item.selected) {
        break;
      }
      current = parent;
    }
    return current ?? widget.node;
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
    return ListenableBuilder(
      listenable: Listenable.merge({
        widget.item.selectedNotifier,
        widget.item.layoutListenable,
      }),
      builder: (context, child) {
        return Transform.translate(
          offset: widget.item.transform.offset * viewportData.zoom,
          child: Transform.rotate(
            angle: widget.item.transform.rotation,
            alignment: Alignment.topLeft,
            child: GroupWidget(
              children: [
                _buildSelection(context),
                ListenableBuilder(
                  listenable: widget.item.childListenable,
                  builder: (context, child) {
                    return GroupWidget(
                      children: [
                        for (final child in widget.item.children)
                          StandardTransformControlWidget(
                            item: child,
                            node: child.toNode(widget.node),
                            parentTransform: widget.parentTransform == null
                                ? widget.item.transform
                                : widget.parentTransform! *
                                    widget.item.transform,
                          ),
                      ],
                    );
                  },
                ),
                if (widget.item.selected) ..._buildControls(context),
              ],
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
    return PanGesture(
      onPanStart: (details) {
        _totalOffset = Offset.zero;
        _session = viewportData.beginTransform();
        _startNode = _findSelected();
        _startLayout = _startNode!.item.layout;
        _snapping = LayoutSnapping(viewportData.snapping, _startNode!.item,
            _startNode!.parentTransform);
        viewportData.fillInSnappingPoints(_snapping!);
      },
      onPanUpdate: (details) {
        Offset delta = details.delta;
        _totalOffset = _totalOffset! + delta / viewportData.zoom;
        void update() {
          TransformNode node = TransformNode(
            _startNode!.item,
            _startNode!.item.transform,
            null,
            _startLayout!,
          );
          visitor(
            node,
            _totalOffset!,
            snapping: _snapping,
          );
          node.apply();
          _session!.visit(
            (node) {
              if (node.item == _startNode!.item) {
                return;
              }
              visitor(node, snapping(_snapping!) ?? _totalOffset!);
            },
          );
          _session!.apply();
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
      },
      child: child,
    );
  }

  Widget _wrapWithRotationHandler({
    required Widget child,
    required Alignment alignment,
  }) {
    Size scaledSize = widget.item.transform.scaledSize * viewportData.zoom;
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
        _session = viewportData.beginTransform();
        _startNode = _findSelected();
        _startLayout = _startNode!.item.layout;
        _snapping = LayoutSnapping(viewportData.snapping, _startNode!.item,
            _startNode!.parentTransform);
        viewportData.fillInSnappingPoints(_snapping!);
      },
      onPanUpdate: (details) {
        void update() {
          var localPosition =
              alignment.alongSize(scaledSize) + details.localPosition;
          var diff = origin - localPosition;
          var angle = diff.direction;
          var delta = angle - _startRotation!;
          _startNode!.item.layout = _startLayout!.rotate(
            delta,
            alignment: !viewportData.anchoredRotate
                ? Alignment.center
                : alignment * -1,
            snapping: _snapping,
          );
          _session!.visit(
            (node) {
              if (node.item == _startNode!.item) {
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

  double _normalizeSize(double size) {
    return size <= 0 ? 0 : size;
  }

  bool get _isScaling => viewportData.resizeMode == ResizeMode.scale;

  List<Widget> _buildControls(BuildContext context) {
    Offset halfSize =
        Offset(theme.handleSize.width / 2, theme.handleSize.height / 2);
    Offset handleSize = Offset(theme.handleSize.width, theme.handleSize.height);
    Offset sizeRotation =
        Offset(theme.rotationHandleSize.width, theme.rotationHandleSize.height);
    Size size = widget.item.transform.scaledSize * viewportData.zoom;
    double xStart = 0;
    double xEnd = size.width;
    double yStart = 0;
    double yEnd = size.height;
    double xRotStart = -halfSize.dx;
    double yRotStart = -halfSize.dy;
    double xRotEnd = size.width + halfSize.dx;
    double yRotEnd = size.height + halfSize.dy;
    bool flipX = size.width < 0;
    bool flipY = size.height < 0;
    if (flipX) {
      xRotEnd = size.width - halfSize.dx - sizeRotation.dx;
      xRotStart = halfSize.dx + sizeRotation.dx;
    }
    if (flipY) {
      yRotEnd = size.height - halfSize.dy - sizeRotation.dy;
      yRotStart = halfSize.dy + sizeRotation.dy;
    }
    return [
      // top left rotation
      Transform.translate(
        offset: Offset(xRotStart, yRotStart) - sizeRotation,
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
        offset: Offset(xRotEnd, yRotStart) + Offset(0, -sizeRotation.dy),
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
        offset: Offset(xRotEnd, yRotEnd),
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
        offset: Offset(xRotStart, yRotEnd) + Offset(-sizeRotation.dx, 0),
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
        offset: Offset(0, yStart) + Offset(halfSize.dx, -halfSize.dy),
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
              width: _normalizeSize(size.width - handleSize.dx),
              height: theme.handleSize.height,
            ),
          ),
        ),
      ),
      // right
      Transform.translate(
        offset: Offset(xEnd, 0) + Offset(-halfSize.dx, halfSize.dy),
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
              height: _normalizeSize(size.height - handleSize.dy),
            ),
          ),
        ),
      ),
      // bottom
      Transform.translate(
        offset: Offset(0, yEnd) + Offset(halfSize.dx, -halfSize.dy),
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
              width: _normalizeSize(size.width - handleSize.dx),
              height: theme.handleSize.height,
            ),
          ),
        ),
      ),
      // left
      Transform.translate(
        offset: Offset(xStart, 0) + Offset(-halfSize.dx, halfSize.dy),
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
              height: _normalizeSize(size.height - handleSize.dy),
            ),
          ),
        ),
      ),
      // top left
      Transform.translate(
        offset: Offset(xStart, yStart) - halfSize,
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
        offset: Offset(xEnd, yStart) + Offset(-halfSize.dx, -halfSize.dy),
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
        offset: Offset(xStart, yEnd) + Offset(-halfSize.dx, -halfSize.dy),
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
        offset: Offset(xEnd, yEnd) + Offset(-halfSize.dx, -halfSize.dy),
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
    Size size = widget.item.transform.scaledSize * viewportData.zoom;
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
          child: Container(
            decoration:
                viewportData.hoveredItem == widget.item || widget.item.selected
                    ? theme.selectionDecoration
                    : null,
          ),
        ),
      ),
    );
  }
}
