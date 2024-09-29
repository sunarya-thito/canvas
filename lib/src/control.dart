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
  Widget build(BuildContext context, CanvasItem node) {
    return StandardTransformControlWidget(item: node);
  }
}

class StandardTransformControlWidget extends StatefulWidget {
  final CanvasItem? parent;
  final CanvasItem item;
  final double parentRotation;

  const StandardTransformControlWidget({
    super.key,
    required this.item,
    this.parent,
    this.parentRotation = 0,
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

  double get globalRotation {
    return widget.item.transform.rotation + widget.parentRotation;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = StandardTransformControlThemeData.defaultThemeData();
    viewportData = CanvasViewportData.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge({
        widget.item.selectedNotifier,
        widget.item.transformNotifier,
      }),
      builder: (context, child) {
        return Transform.translate(
          offset: widget.item.transform.offset,
          child: Transform.rotate(
            angle: widget.item.transform.rotation,
            alignment: Alignment.topLeft,
            child: GroupWidget(
              children: [
                _buildSelection(context),
                ListenableBuilder(
                  listenable: widget.item.childrenNotifier,
                  builder: (context, child) {
                    return GroupWidget(
                      children: [
                        for (final child in widget.item.children)
                          StandardTransformControlWidget(
                            item: child,
                            parent: widget.item,
                            parentRotation: globalRotation,
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
    required void Function(TransformNode node, Offset delta) visitor,
    String? debugName,
  }) {
    return PanGesture(
      onPanStart: (details) {
        _totalOffset = Offset.zero;
        _session = viewportData.beginTransform();
      },
      onPanUpdate: (details) {
        Offset delta = details.delta;
        _totalOffset = _totalOffset! + delta;
        _session!.visit(
          (node) {
            Offset localDelta = _totalOffset!;
            visitor(node, localDelta);
          },
        );
        _session!.apply();
      },
      onPanEnd: (_) {
        _totalOffset = null;
        _session = null;
      },
      onPanCancel: () {
        _session!.reset();
        _totalOffset = null;
        _session = null;
      },
      child: child,
    );
  }

  Widget _wrapWithRotationHandler({
    required Widget child,
    required Alignment alignment,
  }) {
    Size scaledSize = widget.item.transform.scaledSize;
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
      },
      onPanUpdate: (details) {
        var localPosition =
            alignment.alongSize(scaledSize) + details.localPosition;
        var diff = origin - localPosition;
        var angle = diff.direction;
        var delta = angle - _startRotation!;
        _session!.visit(
          (node) {
            node.newLayout = node.layout.rotate(
                delta,
                !viewportData.anchoredRotate
                    ? Alignment.center
                    : alignment * -1);
          },
        );
        _session!.apply();
      },
      onPanEnd: (details) {
        _startRotation = null;
        _session = null;
      },
      onPanCancel: () {
        if (_session != null) {
          _session!.reset();
        }
        _startRotation = null;
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
    Size size = widget.item.transform.scaledSize;
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleTop(
                  delta,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeTop(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleRight(
                  delta,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeRight(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleBottom(
                  delta,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottom(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleLeft(
                  delta,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeLeft(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleTopLeft(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeTopLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleTopRight(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeTopRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleBottomLeft(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottomLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
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
            visitor: (node, delta) {
              if (_isScaling) {
                node.newLayout = node.layout.rescaleBottomRight(
                  delta,
                  proportional: viewportData.proportionalResize,
                  symmetric: viewportData.symmetricResize,
                );
                return;
              }
              node.newLayout = node.layout.resizeBottomRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
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
    Size size = widget.item.transform.scaledSize;
    Offset flipOffset = Offset(
      size.width < 0 ? size.width : 0,
      size.height < 0 ? size.height : 0,
    );
    size = size.abs();
    return Transform.translate(
      offset: flipOffset,
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        cursor: widget.item.selected
            ? SystemMouseCursors.move
            : SystemMouseCursors.click,
        opaque: false,
        onEnter: (_) {
          setState(() {
            _hover = true;
          });
        },
        onExit: (_) {
          setState(() {
            _hover = false;
          });
        },
        child: IgnorePointer(
          child: SizedBox.fromSize(
            size: size,
            child: Container(
              decoration: _hover || widget.item.selected
                  ? theme.selectionDecoration
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
