import 'dart:math';

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
    Key? key,
    required this.item,
    this.parent,
    this.parentRotation = 0,
  }) : super(key: key);

  @override
  State<StandardTransformControlWidget> createState() =>
      _StandardTransformControlWidgetState();
}

int _findClosestAngle(double radians) {
  var degrees = radians * 180 / pi;
  degrees = degrees % 360;
  if (degrees < 0) {
    degrees += 360;
  }
  return ((degrees + 22.5) ~/ 45) % 8;
}

List<MouseCursor> _cursorRotations = [
  SystemMouseCursors.resizeUpDown, // 0
  SystemMouseCursors.resizeUpRight, // 45
  SystemMouseCursors.resizeLeftRight, // 90
  SystemMouseCursors.resizeDownRight, // 135
  SystemMouseCursors.resizeUpDown, // 180
  SystemMouseCursors.resizeDownLeft, // 225
  SystemMouseCursors.resizeLeftRight, // 270
  SystemMouseCursors.resizeUpLeft, // 315
];

enum _MouseCursor {
  _top,
  _topRight,
  _right,
  _bottomRight,
  _bottom,
  _bottomLeft,
  _left,
  _topLeft;

  double get angle {
    return index * 45 * pi / 180;
  }

  MouseCursor _rotate(double angle) {
    angle += this.angle;
    return _cursorRotations[_findClosestAngle(angle)];
  }
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
                for (final child in widget.item.children)
                  StandardTransformControlWidget(
                    item: child,
                    parent: widget.item,
                    parentRotation: globalRotation,
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
  }) {
    return PanGesture(
      onPanStart: (details) {
        _totalOffset = Offset.zero;
        _session = viewportData.beginTransform();
      },
      onPanUpdate: (details) {
        Offset delta = details.delta;
        delta = rotatePoint(delta, globalRotation);
        _totalOffset = _totalOffset! + delta;
        _session!.visit(
          (node) {
            Offset localDelta = _totalOffset!;
            if (node.parentTransform != null) {
              localDelta =
                  rotatePoint(localDelta, -node.parentTransform!.rotation);
            }
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
  }) {
    return child;
  }

  List<Widget> _buildControls(BuildContext context) {
    Offset halfSize =
        Offset(theme.handleSize.width / 2, theme.handleSize.height / 2);
    Offset handleSize = Offset(theme.handleSize.width, theme.handleSize.height);
    Offset sizeRotation =
        Offset(theme.rotationHandleSize.width, theme.rotationHandleSize.height);
    Size size = widget.item.transform.scaledSize;
    return [
      // top left rotation
      Transform.translate(
        offset: -halfSize - sizeRotation,
        child: MouseRegion(
          cursor: _MouseCursor._bottomLeft._rotate(globalRotation),
          child: SizedBox(
            width: theme.rotationHandleSize.width,
            height: theme.rotationHandleSize.height,
          ),
        ),
      ),
      // top right rotation
      Transform.translate(
        offset:
            Offset(size.width + halfSize.dx, -halfSize.dy - sizeRotation.dy),
        child: MouseRegion(
          cursor: _MouseCursor._bottomRight._rotate(globalRotation),
          child: SizedBox(
            width: theme.rotationHandleSize.width,
            height: theme.rotationHandleSize.height,
          ),
        ),
      ),
      // bottom right rotation
      Transform.translate(
        offset: Offset(size.width + halfSize.dx, size.height + halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._topRight._rotate(globalRotation),
          child: SizedBox(
            width: theme.rotationHandleSize.width,
            height: theme.rotationHandleSize.height,
          ),
        ),
      ),
      // bottom left rotation
      Transform.translate(
        offset:
            Offset(-halfSize.dx - sizeRotation.dx, size.height + halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._topLeft._rotate(globalRotation),
          child: SizedBox(
            width: theme.rotationHandleSize.width,
            height: theme.rotationHandleSize.height,
          ),
        ),
      ),
      // top
      Transform.translate(
        offset: Offset(halfSize.dx, -halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._top._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeTop(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: SizedBox(
              width: size.width - handleSize.dx,
              height: theme.handleSize.height,
            ),
          ),
        ),
      ),
      // right
      Transform.translate(
        offset: Offset(size.width - halfSize.dx, halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._right._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeRight(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: SizedBox(
              width: theme.handleSize.width,
              height: size.height - handleSize.dy,
            ),
          ),
        ),
      ),
      // bottom
      Transform.translate(
        offset: Offset(halfSize.dx, size.height - halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._bottom._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeBottom(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: SizedBox(
              width: size.width - handleSize.dx,
              height: theme.handleSize.height,
            ),
          ),
        ),
      ),
      // left
      Transform.translate(
        offset: Offset(-halfSize.dx, halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._left._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeLeft(
                delta,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: SizedBox(
              width: theme.handleSize.width,
              // height: rect.height - theme.handleSize.height,
              height: size.height - handleSize.dy,
            ),
          ),
        ),
      ),
      // top left
      Transform.translate(
        offset: -halfSize,
        child: MouseRegion(
          cursor: _MouseCursor._topLeft._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeTopLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration: theme.decoration,
            ),
          ),
        ),
      ),
      // top right
      Transform.translate(
        offset: Offset(size.width - halfSize.dx, -halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._topRight._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeTopRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration: theme.decoration,
            ),
          ),
        ),
      ),
      // bottom left
      Transform.translate(
        offset: Offset(-halfSize.dx, size.height - halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._bottomLeft._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeBottomLeft(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration: theme.decoration,
            ),
          ),
        ),
      ),
      // bottom right
      Transform.translate(
        offset: Offset(size.width - halfSize.dx, size.height - halfSize.dy),
        child: MouseRegion(
          cursor: _MouseCursor._bottomRight._rotate(globalRotation),
          child: _wrapWithPanHandler(
            visitor: (node, delta) {
              node.newLayout = node.layout.resizeBottomRight(
                delta,
                proportional: viewportData.proportionalResize,
                symmetric: viewportData.symmetricResize,
              );
            },
            child: Container(
              width: theme.handleSize.width,
              height: theme.handleSize.height,
              decoration: theme.decoration,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSelection(BuildContext context) {
    Size size = widget.item.transform.scaledSize;
    return ListenableBuilder(
        listenable: widget.item.selectedNotifier,
        builder: (context, child) {
          return MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            cursor: widget.item.selected
                ? SystemMouseCursors.move
                : SystemMouseCursors.click,
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
            child: GestureDetector(
              onTap: () {
                if (viewportData.multiSelect) {
                  widget.item.selected = !widget.item.selected;
                } else {
                  viewportData.visit(
                    (item) {
                      item.selected = item == widget.item;
                    },
                  );
                }
              },
              child: PanGesture(
                onPanStart: (_) {
                  if (!widget.item.selected) {
                    if (viewportData.multiSelect) {
                      widget.item.selected = !widget.item.selected;
                    } else {
                      viewportData.visit(
                        (item) {
                          item.selected = item == widget.item;
                        },
                      );
                    }
                  }
                  _session =
                      viewportData.beginTransform(rootSelectionOnly: true);
                  _totalOffset = Offset.zero;
                },
                onPanUpdate: (details) {
                  Offset delta = details.delta;
                  delta = rotatePoint(delta, globalRotation);
                  _totalOffset = _totalOffset! + delta;
                  _session!.visit(
                    (node) {
                      Offset localDelta = _totalOffset!;
                      if (node.parentTransform != null) {
                        localDelta = rotatePoint(
                            localDelta, -node.parentTransform!.rotation);
                      }
                      node.newLayout = node.layout.drag(localDelta);
                    },
                  );
                  _session!.apply();
                },
                onPanEnd: (_) {
                  _totalOffset = null;
                  _session = null;
                },
                onPanCancel: () {
                  if (_session != null) {
                    _session!.reset();
                  }
                  _totalOffset = null;
                  _session = null;
                },
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
        });
  }
}
