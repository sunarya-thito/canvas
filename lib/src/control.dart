import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

class StandardTransformControlThemeData {
  final Decoration macroDecoration;
  final Decoration microDecoration;
  final Decoration macroScaleDecoration;
  final Decoration microScaleDecoration;
  final Color selectionBorderColor;
  final double selectionBorderWidth;
  final Decoration rotationHandleDecoration;
  final double rotationLineLength;
  final double rotationLineBorderWidth;
  final Color rotationLineBorderColor;

  final Size macroSize;
  final Size microSize;
  final Size rotationHandleSize;

  const StandardTransformControlThemeData({
    required this.macroDecoration,
    required this.microDecoration,
    required this.macroScaleDecoration,
    required this.microScaleDecoration,
    required this.selectionBorderColor,
    required this.selectionBorderWidth,
    required this.macroSize,
    required this.microSize,
    required this.rotationHandleDecoration,
    required this.rotationLineLength,
    required this.rotationLineBorderWidth,
    required this.rotationLineBorderColor,
    required this.rotationHandleSize,
  });

  factory StandardTransformControlThemeData.defaultThemeData() {
    return StandardTransformControlThemeData(
      macroDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFFFFFF),
      ),
      microDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFFFFFF),
      ),
      macroScaleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFF0000),
      ),
      microScaleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFF0000),
      ),
      selectionBorderColor: const Color(0xFF000000),
      selectionBorderWidth: 1,
      macroSize: const Size(10, 10),
      microSize: const Size(8, 8),
      rotationHandleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFFFFFF),
        shape: BoxShape.circle,
      ),
      rotationHandleSize: const Size(10, 10),
      rotationLineLength: 20,
      rotationLineBorderWidth: 1,
      rotationLineBorderColor: const Color(0xFF000000),
    );
  }
}

typedef UnaryOpertor<T> = T Function(T oldValue, T value);

enum ResizeMode {
  none,
  scale,
  resize,
}

class TransformControlWidget extends StatefulWidget {
  final TransformControl control;
  final CanvasItemNode node;
  final Matrix4? parentTransform;
  final ResizeMode resizeMode;

  const TransformControlWidget({
    super.key,
    required this.node,
    required this.control,
    this.parentTransform,
    required this.resizeMode,
  });

  @override
  State<TransformControlWidget> createState() => _TransformControlWidgetState();
}

class _TransformControlWidgetState extends State<TransformControlWidget>
    implements TransformControlHandler {
  @override
  CanvasItemNode get node => widget.node;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge({
        node.matrixNotifier,
        node.item.childrenNotifier,
        node.item.controlFlagNotifier,
        node.item.transformControlModeNotifier,
      }),
      builder: (context, child) {
        List<Widget> children = [];
        var matrix = node.matrix;
        if (widget.parentTransform != null) {
          matrix = widget.parentTransform! * matrix;
        }
        for (var child in node.children) {
          children.add(
            TransformControlWidget(
              node: child,
              control: widget.control,
              resizeMode: widget.resizeMode,
              parentTransform: matrix,
            ),
          );
        }
        return GroupWidget(
          children: [
            widget.control.buildControl(
              context,
              this,
              matrix,
            ),
            ...children,
          ],
        );
      },
    );
  }

  @override
  void move(Offset delta) {
    delta = rotatePoint(delta, node.item.transform.rotation);
    node.item.dispatchTransformChanging(
      node.item.transform.drag(delta),
    );
  }

  @override
  void resizeBottom(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeBottom(delta),
    );
  }

  @override
  void resizeBottomLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeBottomLeft(delta),
    );
  }

  @override
  void resizeBottomRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeBottomRight(delta),
    );
  }

  @override
  void resizeLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeLeft(delta),
    );
  }

  @override
  ResizeMode get resizeMode => widget.resizeMode;

  @override
  void resizeRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeRight(delta),
    );
  }

  @override
  void resizeTop(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeTop(delta),
    );
  }

  @override
  void resizeTopLeft(Offset delta) {
    // delta = delta.scale(
    //     node.item.transform.scale.width, node.item.transform.scale.height);
    // delta = rotatePoint(delta, node.item.transform.rotation);
    node.item.dispatchTransformChanging(
      node.item.transform.resizeTopLeft(delta),
    );
  }

  @override
  void resizeTopRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resizeTopRight(delta),
    );
  }

  @override
  void rotate(double delta, Alignment alignment) {
    node.item.dispatchTransformChanging(
      node.item.transform.rotate(delta, alignment),
    );
  }

  @override
  void scaleBottom(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleBottom(delta),
    );
  }

  @override
  void scaleBottomLeft(Offset delta) {
    // TODO: implement scaleBottomLeft
  }

  @override
  void scaleBottomRight(Offset delta) {
    // TODO: implement scaleBottomRight
  }

  @override
  void scaleLeft(Offset delta) {
    // TODO: implement scaleLeft
  }

  @override
  void scaleRight(Offset delta) {
    // TODO: implement scaleRight
  }

  @override
  void scaleTop(Offset delta) {
    // TODO: implement scaleTop
  }

  @override
  void scaleTopLeft(Offset delta) {
    // TODO: implement scaleTopLeft
  }

  @override
  void scaleTopRight(Offset delta) {
    // TODO: implement scaleTopRight
  }
}

abstract class TransformControlHandler {
  CanvasItemNode get node;
  ResizeMode get resizeMode;
  void resizeTopLeft(Offset delta);
  void resizeTopRight(Offset delta);
  void resizeBottomLeft(Offset delta);
  void resizeBottomRight(Offset delta);
  void resizeTop(Offset delta);
  void resizeLeft(Offset delta);
  void resizeRight(Offset delta);
  void resizeBottom(Offset delta);
  void rotate(double delta, Alignment alignment);
  void scaleTopLeft(Offset delta);
  void scaleTopRight(Offset delta);
  void scaleBottomLeft(Offset delta);
  void scaleBottomRight(Offset delta);
  void scaleTop(Offset delta);
  void scaleLeft(Offset delta);
  void scaleRight(Offset delta);
  void scaleBottom(Offset delta);
  void move(Offset delta);
}

double matrixRotationToAngle(Matrix4 matrix) {
  // We only care about the 2D rotation part (the z-axis)
  final double angleFromMatrix = atan2(matrix.entry(1, 0), matrix.entry(0, 0));
  return angleFromMatrix;
}

abstract class TransformControl {
  Widget buildControl(
      BuildContext context, TransformControlHandler handler, Matrix4 matrix);
}

class StandardTransformControlTheme extends InheritedTheme {
  final StandardTransformControlThemeData data;

  const StandardTransformControlTheme({
    super.key,
    required this.data,
    required Widget child,
  }) : super(child: child);

  static StandardTransformControlThemeData of(BuildContext context) {
    final StandardTransformControlTheme? result = context
        .dependOnInheritedWidgetOfExactType<StandardTransformControlTheme>();
    return result?.data ?? StandardTransformControlThemeData.defaultThemeData();
  }

  @override
  bool updateShouldNotify(StandardTransformControlTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final StandardTransformControlTheme? ancestor =
        context.findAncestorWidgetOfExactType<StandardTransformControlTheme>();
    return identical(this, ancestor)
        ? child
        : StandardTransformControlTheme(data: data, child: child);
  }
}

Offset _transformPoint(Matrix4 matrix, Offset point) {
  return MatrixUtils.transformPoint(matrix, point);
}

double _angleOfLine(Offset start, Offset end) {
  return atan2(end.dy - start.dy, end.dx - start.dx);
}

class StandardTransformControl extends TransformControl {
  @override
  Widget buildControl(
      BuildContext context, TransformControlHandler handler, Matrix4 matrix) {
    return _StandardTransformControlWidget(
      handler: handler,
      matrix: matrix,
    );
  }
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

class _StandardTransformControlWidget extends StatelessWidget {
  final TransformControlHandler handler;
  final Matrix4 matrix;

  const _StandardTransformControlWidget({
    required this.handler,
    required this.matrix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = StandardTransformControlTheme.of(context);
    var size = handler.node.item.transform.size;
    var scale = handler.node.item.transform.scale;
    size = Size(size.width * scale.width, size.height * scale.height);
    var topLeftPoint = _transformPoint(matrix, Offset(0, 0));
    var topRightPoint = _transformPoint(matrix, Offset(size.width, 0));
    var bottomLeftPoint = _transformPoint(matrix, Offset(0, size.height));
    var bottomRightPoint =
        _transformPoint(matrix, Offset(size.width, size.height));
    var topPoint = _transformPoint(matrix, Offset(size.width / 2, 0));
    var leftPoint = _transformPoint(matrix, Offset(0, size.height / 2));
    var rightPoint =
        _transformPoint(matrix, Offset(size.width, size.height / 2));
    var bottomPoint =
        _transformPoint(matrix, Offset(size.width / 2, size.height));
    var topLeftAngle = _angleOfLine(topLeftPoint, topRightPoint);
    var topRightAngle = _angleOfLine(topRightPoint, bottomRightPoint);
    var bottomLeftAngle = _angleOfLine(topLeftPoint, bottomLeftPoint);
    var bottomRightAngle = _angleOfLine(bottomLeftPoint, bottomRightPoint);
    var topAngle = _angleOfLine(topLeftPoint, topRightPoint);
    var leftAngle = _angleOfLine(topLeftPoint, bottomLeftPoint);
    var rightAngle = _angleOfLine(topRightPoint, bottomRightPoint);
    var bottomAngle = _angleOfLine(bottomLeftPoint, bottomRightPoint);
    var isResizeMode = handler.resizeMode == ResizeMode.resize;
    var macroDecoration =
        isResizeMode ? theme.macroDecoration : theme.macroScaleDecoration;
    var macroSize = theme.macroSize;
    var microSize = theme.microSize;
    var microDecoration =
        isResizeMode ? theme.microDecoration : theme.microScaleDecoration;

    return GroupWidget(
      children: handler.node.item.transformControlMode ==
              TransformControlMode.show
          ? [
              CustomPaint(
                painter: _StandardTransformControlPainter(
                  theme: theme,
                  topLeftPoint: topLeftPoint,
                  topRightPoint: topRightPoint,
                  bottomLeftPoint: bottomLeftPoint,
                  bottomRightPoint: bottomRightPoint,
                ),
              ),
              CanvasTransformed(
                matrix4: matrix,
                size: size,
                background: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  hitTestBehavior: HitTestBehavior.translucent,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      handler.move(details.delta);
                    },
                  ),
                ),
              ),
              // Top left
              CanvasTransformed(
                matrix4: _getPointMatrix(topLeftPoint, topLeftAngle, macroSize),
                size: macroSize,
                background: Container(
                  decoration: macroDecoration,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // handler.resizeTopLeft(details);
                    },
                    child: MouseRegion(
                      cursor: _MouseCursor._topLeft._rotate(topLeftAngle),
                    ),
                  ),
                ),
              ),
              // Top right
              CanvasTransformed(
                matrix4:
                    _getPointMatrix(topRightPoint, topRightAngle, macroSize),
                size: macroSize,
                background: MouseRegion(
                  cursor:
                      _MouseCursor._topRight._rotate(topRightAngle - pi / 2),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeTopRight(details.delta);
                    },
                    child: Container(
                      decoration: macroDecoration,
                    ),
                  ),
                ),
              ),
              // Bottom left
              CanvasTransformed(
                matrix4: _getPointMatrix(
                    bottomLeftPoint, bottomLeftAngle, macroSize),
                size: macroSize,
                background: MouseRegion(
                  cursor: _MouseCursor._bottomLeft
                      ._rotate(bottomLeftAngle - pi / 2),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeBottomLeft(details.delta);
                    },
                    child: Container(
                      decoration: macroDecoration,
                    ),
                  ),
                ),
              ),
              // Bottom right
              CanvasTransformed(
                matrix4: _getPointMatrix(
                    bottomRightPoint, bottomRightAngle, macroSize),
                size: macroSize,
                background: MouseRegion(
                  cursor: _MouseCursor._bottomRight._rotate(bottomRightAngle),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeBottomRight(details.delta);
                    },
                    child: Container(
                      decoration: macroDecoration,
                    ),
                  ),
                ),
              ),
              // Top
              CanvasTransformed(
                matrix4: _getPointMatrix(topPoint, topAngle, microSize),
                size: microSize,
                background: MouseRegion(
                  cursor: _MouseCursor._top._rotate(topAngle),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeTop(details.delta);
                    },
                    child: Container(
                      decoration: microDecoration,
                    ),
                  ),
                ),
              ),
              // Left
              CanvasTransformed(
                matrix4: _getPointMatrix(leftPoint, leftAngle, microSize),
                size: microSize,
                background: MouseRegion(
                  cursor: _MouseCursor._left._rotate(leftAngle - pi / 2),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeLeft(details.delta);
                    },
                    child: Container(
                      decoration: microDecoration,
                    ),
                  ),
                ),
              ),
              // Right
              CanvasTransformed(
                matrix4: _getPointMatrix(rightPoint, rightAngle, microSize),
                size: microSize,
                background: MouseRegion(
                  cursor: _MouseCursor._right._rotate(rightAngle - pi / 2),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeRight(details.delta);
                    },
                    child: Container(
                      decoration: microDecoration,
                    ),
                  ),
                ),
              ),
              // Bottom
              CanvasTransformed(
                matrix4: _getPointMatrix(bottomPoint, bottomAngle, microSize),
                size: microSize,
                background: MouseRegion(
                  cursor: _MouseCursor._bottom._rotate(bottomAngle),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      handler.resizeBottom(details.delta);
                    },
                    child: Container(
                      decoration: microDecoration,
                    ),
                  ),
                ),
              ),
            ]
          : [],
    );
  }
}

Matrix4 _inverseMatrix(Matrix4 matrix) {
  Matrix4 copy = Matrix4.copy(matrix);
  copy.invert();
  return copy;
}

Matrix4 _getPointMatrix(Offset offset, double angle, Size size) {
  return Matrix4.identity()
    ..translate(offset.dx, offset.dy)
    ..rotateZ(angle)
    ..translate(-size.width / 2, -size.height / 2);
}

Matrix4 _inversePointMatrix(double angle) {
  return Matrix4.identity()..rotateZ(-angle);
}

Offset _inverseOffset(Offset offset, double angle) {
  final matrix = _inversePointMatrix(angle);
  return _transformPoint(matrix, offset);
}

class _StandardTransformControlPainter extends CustomPainter {
  final Offset topLeftPoint;
  final Offset topRightPoint;
  final Offset bottomLeftPoint;
  final Offset bottomRightPoint;
  final StandardTransformControlThemeData theme;

  const _StandardTransformControlPainter({
    required this.theme,
    required this.topLeftPoint,
    required this.topRightPoint,
    required this.bottomLeftPoint,
    required this.bottomRightPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final selectionPaint = Paint()
      ..color = theme.selectionBorderColor
      ..strokeWidth = theme.selectionBorderWidth
      ..style = PaintingStyle.stroke;
    Path selectionPath = Path()
      ..moveTo(topLeftPoint.dx, topLeftPoint.dy)
      ..lineTo(topRightPoint.dx, topRightPoint.dy)
      ..lineTo(bottomRightPoint.dx, bottomRightPoint.dy)
      ..lineTo(bottomLeftPoint.dx, bottomLeftPoint.dy)
      ..close();
    canvas.drawPath(selectionPath, selectionPaint);
  }

  @override
  bool shouldRepaint(covariant _StandardTransformControlPainter oldDelegate) {
    return oldDelegate.topLeftPoint != topLeftPoint ||
        oldDelegate.topRightPoint != topRightPoint ||
        oldDelegate.bottomLeftPoint != bottomLeftPoint ||
        oldDelegate.bottomRightPoint != bottomRightPoint;
  }
}
