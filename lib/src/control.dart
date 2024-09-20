import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

class StandardTransformControlThemeData {
  final Decoration macroDecoration;
  final Decoration microDecoration;
  final Decoration macroScaleDecoration;
  final Decoration microScaleDecoration;
  final Decoration rotationHandleDecoration;
  final double rotationLineLength;
  final double rotationLineBorderWidth;
  final Color rotationLineBorderColor;
  final Decoration selectionDecoration;

  final Size macroSize;
  final Size microSize;
  final Size rotationHandleSize;

  const StandardTransformControlThemeData({
    required this.macroDecoration,
    required this.microDecoration,
    required this.macroScaleDecoration,
    required this.microScaleDecoration,
    required this.selectionDecoration,
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
      selectionDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0x00000000),
      ),
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
  final bool uniform;
  final bool keepAspectRatio;

  const TransformControlWidget({
    super.key,
    required this.node,
    required this.control,
    this.parentTransform,
    required this.resizeMode,
    this.uniform = false,
    this.keepAspectRatio = false,
  });

  @override
  State<TransformControlWidget> createState() => _TransformControlWidgetState();
}

class _TransformControlWidgetState extends State<TransformControlWidget>
    implements TransformControlHandler {
  @override
  CanvasItemNode get node => widget.node;

  @override
  Matrix4 get matrix {
    if (widget.parentTransform != null) {
      return widget.parentTransform! * node.matrix;
    }
    return node.matrix;
  }

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
      node.item.transform.drag(node, delta),
    );
  }

  @override
  void resizeBottom(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.bottomCenter,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeBottomLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.bottomLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeBottomRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.bottomRight,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.centerLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  ResizeMode get resizeMode => widget.resizeMode;

  @override
  void resizeRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.centerRight,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeTop(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.topCenter,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeTopLeft(Offset delta) {
    // delta = delta.scale(
    //     node.item.transform.scale.width, node.item.transform.scale.height);
    // delta = rotatePoint(delta, node.item.transform.rotation);
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.topLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void resizeTopRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.resize(node, delta, Alignment.topRight,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void rotate(double angle, Alignment alignment) {
    node.item.dispatchTransformChanging(
        node.item.transform.rotate(node, angle, Alignment.center));
  }

  @override
  void scaleBottom(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.bottomCenter,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleBottomLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.bottomLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleBottomRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.bottomRight,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.centerLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.centerRight,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleTop(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.topCenter,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleTopLeft(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.topLeft,
          widget.uniform ? Alignment.center : null),
    );
  }

  @override
  void scaleTopRight(Offset delta) {
    node.item.dispatchTransformChanging(
      node.item.transform.scaleTransform(node, delta, Alignment.topRight,
          widget.uniform ? Alignment.center : null),
    );
  }
}

abstract class TransformControlHandler {
  CanvasItemNode get node;
  ResizeMode get resizeMode;
  Matrix4 get matrix;
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
  Widget buildControl(BuildContext context, TransformControlHandler handler);
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
  Widget buildControl(BuildContext context, TransformControlHandler handler) {
    return _StandardTransformControlWidget(
      handler: handler,
      matrix: handler.matrix,
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
    var transform = handler.node.item.transform;
    var size = transform.size;
    var scale = transform.scale;
    size = Size(size.width * scale.dx, size.height * scale.dy);
    return GroupWidget(
      children: [
        Transform(
          transform: matrix,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Container(
              decoration: theme.selectionDecoration,
            ),
          ),
        )
      ],
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
