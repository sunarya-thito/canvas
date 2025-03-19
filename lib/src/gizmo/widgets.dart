import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasItemGizmo extends StatefulWidget {
  final CanvasItemState state;
  final Matrix4? parentTransform;
  final double? parentRotation;

  const CanvasItemGizmo({
    Key? key,
    required this.state,
    this.parentTransform,
    this.parentRotation,
  }) : super(key: key);

  @override
  State<CanvasItemGizmo> createState() => _CanvasItemGizmoState();
}

class _CanvasItemGizmoState extends State<CanvasItemGizmo> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant CanvasItemGizmo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_update);
      widget.state.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    assert(
        widget.state.hasSize, 'CanvasItemGizmo requires a laid out CanvasItem');
    Offset position = widget.state.parentData.position;
    Offset? editorOffset = widget.state.item.editorOffset;
    Matrix4 parentTransform =
        widget.parentTransform?.clone() ?? Matrix4.identity();
    parentTransform.translate(position.dx, position.dy);
    Matrix4 transform = widget.state.item.layoutData
        .computeMatrix(widget.state.size, parentMatrix: parentTransform);

    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }

    double rotation = widget.state.item.layoutData.rotation ?? 0;

    if (widget.parentRotation != null) {
      rotation += widget.parentRotation!;
    }

    var innerSize =
        widget.state.item.layoutData.computeInnerSize(widget.state.size);

    return GroupData(
      position: Offset.zero,
      child: GroupWidget(
        size: widget.state.size,
        children: [
          for (var child in widget.state.children)
            CanvasItemGizmo(
              key: child.gizmoKey,
              state: child,
              parentTransform: transform,
              parentRotation: rotation,
            ),
          if (widget.state.item is! CanvasRoot)
            IgnorePointer(
              child: SizedBox.fromSize(
                size: innerSize,
                child: CustomPaint(
                  painter: GizmoPainter(
                    handleBorderColor: Color.fromARGB(255, 8, 255, 234),
                    handleFillColor: Color.fromARGB(255, 52, 162, 212),
                    handleBorderWidth: 1,
                    handleSize: 10,
                    transform: transform,
                    rotation: rotation,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GizmoPainter extends CustomPainter {
  final Color? borderColor;
  final Color? fillColor;
  final double? borderWidth;
  final Color? handleBorderColor;
  final Color? handleFillColor;
  final double? handleBorderWidth;
  final double? handleSize;
  final Matrix4 transform;
  final double rotation;

  GizmoPainter({
    this.borderColor,
    this.fillColor,
    this.borderWidth,
    this.handleBorderColor,
    this.handleFillColor,
    this.handleBorderWidth,
    this.handleSize,
    required this.transform,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = Offset(0, 0);
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);

    final transformedTopLeft = transformOffset(topLeft, transform);
    final transformedTopRight = transformOffset(topRight, transform);
    final transformedBottomLeft = transformOffset(bottomLeft, transform);
    final transformedBottomRight = transformOffset(bottomRight, transform);

    final borderColor = this.borderColor;
    final fillColor = this.fillColor;
    final borderWidth = this.borderWidth;
    final handleBorderColor = this.handleBorderColor;
    final handleFillColor = this.handleFillColor;
    final handleBorderWidth = this.handleBorderWidth;
    final handleSize = this.handleSize;

    Path? boundingBoxPath;

    if (fillColor != null) {
      boundingBoxPath ??= Path()
        ..moveTo(transformedTopLeft.dx, transformedTopLeft.dy)
        ..lineTo(transformedTopRight.dx, transformedTopRight.dy)
        ..lineTo(transformedBottomRight.dx, transformedBottomRight.dy)
        ..lineTo(transformedBottomLeft.dx, transformedBottomLeft.dy)
        ..close();

      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(boundingBoxPath, paint);
    }

    if (borderColor != null && borderWidth != null) {
      boundingBoxPath ??= Path()
        ..moveTo(transformedTopLeft.dx, transformedTopLeft.dy)
        ..lineTo(transformedTopRight.dx, transformedTopRight.dy)
        ..lineTo(transformedBottomRight.dx, transformedBottomRight.dy)
        ..lineTo(transformedBottomLeft.dx, transformedBottomLeft.dy)
        ..close();

      final paint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(boundingBoxPath, paint);
    }

    if (handleSize != null && handleSize > 0) {
      Size handle = Size(handleSize, handleSize);

      final handleTopLeft = Polygon.fromRect(Rect.fromCenter(
        center: transformedTopLeft,
        width: handle.width,
        height: handle.height,
      ));
      final handleTopRight = Polygon.fromRect(Rect.fromCenter(
        center: transformedTopRight,
        width: handle.width,
        height: handle.height,
      ));
      final handleBottomLeft = Polygon.fromRect(Rect.fromCenter(
        center: transformedBottomLeft,
        width: handle.width,
        height: handle.height,
      ));
      final handleBottomRight = Polygon.fromRect(Rect.fromCenter(
        center: transformedBottomRight,
        width: handle.width,
        height: handle.height,
      ));

      Matrix4 rotationMatrix = Matrix4.identity();
      rotationMatrix.rotateZ(rotation);

      final transformedHandleTopLeft =
          handleTopLeft.transform(rotationMatrix, transformedTopLeft);
      final transformedHandleTopRight =
          handleTopRight.transform(rotationMatrix, transformedTopRight);
      final transformedHandleBottomLeft =
          handleBottomLeft.transform(rotationMatrix, transformedBottomLeft);
      final transformedHandleBottomRight =
          handleBottomRight.transform(rotationMatrix, transformedBottomRight);

      if (handleFillColor != null) {
        final paint = Paint()
          ..color = handleFillColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(transformedHandleTopLeft.path, paint);
        canvas.drawPath(transformedHandleTopRight.path, paint);
        canvas.drawPath(transformedHandleBottomLeft.path, paint);
        canvas.drawPath(transformedHandleBottomRight.path, paint);
      }

      if (handleBorderColor != null && handleBorderWidth != null) {
        final paint = Paint()
          ..color = handleBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = handleBorderWidth;
        canvas.drawPath(transformedHandleTopLeft.path, paint);
        canvas.drawPath(transformedHandleTopRight.path, paint);
        canvas.drawPath(transformedHandleBottomLeft.path, paint);
        canvas.drawPath(transformedHandleBottomRight.path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GizmoPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.handleBorderColor != handleBorderColor ||
        oldDelegate.handleFillColor != handleFillColor ||
        oldDelegate.handleBorderWidth != handleBorderWidth ||
        oldDelegate.handleSize != handleSize;
  }
}
