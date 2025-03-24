import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasItemGizmo extends StatefulWidget {
  final CanvasItemState state;
  final Matrix4? parentTransform;
  final Offset? parentScale;

  const CanvasItemGizmo({
    Key? key,
    required this.state,
    this.parentTransform,
    this.parentScale,
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

    Offset scale = widget.state.item.layoutData.scale ?? Offset(1, 1);

    if (widget.parentScale != null) {
      scale = Offset(
        scale.dx * widget.parentScale!.dx,
        scale.dy * widget.parentScale!.dy,
      );
    }

    var innerSize =
        widget.state.item.layoutData.computeInnerSize(widget.state.size);

    Widget _createHandle(
        Alignment alignment, bool expandWidth, bool expandHeight) {
      return GestureDetector(
        onPanUpdate: (details) {},
        child: CustomPaint(
          painter: GizmoHandlePainter(
            handleBorderColor: Color.fromARGB(255, 0, 0, 0),
            handleFillColor: Color.fromARGB(255, 255, 255, 255),
            handleBorderWidth: 1,
            handleWidth: expandWidth ? innerSize.width : 10,
            handleHeight: expandHeight ? innerSize.height : 10,
            transform: transform,
            scale: Offset(
              expandWidth ? 1 : scale.dx,
              expandHeight ? 1 : scale.dy,
            ),
            size: innerSize,
            alignment: alignment,
          ),
        ),
      );
    }

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
              parentScale: scale,
            ),
          if (widget.state.item is! CanvasRoot) ...[
            // top
            _createHandle(Alignment.topCenter, true, false),
            // bottom
            _createHandle(Alignment.bottomCenter, true, false),
            // left
            _createHandle(Alignment.centerLeft, false, true),
            // right
            _createHandle(Alignment.centerRight, false, true),
            // top left
            _createHandle(Alignment.topLeft, false, false),
            // top right
            _createHandle(Alignment.topRight, false, false),
            // bottom left
            _createHandle(Alignment.bottomLeft, false, false),
            // bottom right
            _createHandle(Alignment.bottomRight, false, false),
          ],
        ],
      ),
    );
  }
}

class GizmoHandlePainter extends CustomPainter {
  final Color? handleBorderColor;
  final Color? handleFillColor;
  final double? handleBorderWidth;
  final double handleWidth;
  final double handleHeight;
  final Matrix4 transform;
  final Offset scale;
  final Size size;
  final Alignment alignment;

  GizmoHandlePainter({
    this.handleBorderColor,
    this.handleFillColor,
    this.handleBorderWidth,
    required this.handleWidth,
    required this.handleHeight,
    required this.transform,
    required this.scale,
    required this.size,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final handleFillColor = this.handleFillColor;
    final handleBorderColor = this.handleBorderColor;
    final handleBorderWidth = this.handleBorderWidth;
    if (handleFillColor == null &&
        (handleBorderColor == null || handleBorderWidth == null)) {
      return;
    }
    final center = alignment.alongSize(this.size);
    final polygon = Polygon.fromRect(
      Rect.fromCenter(
        center: center,
        width: handleWidth,
        height: handleHeight,
      ),
    );
    final transform = this.transform.clone();
    transform.translate(center.dx, center.dy);
    transform.scale(1 / scale.dx, 1 / scale.dy);
    transform.translate(-center.dx, -center.dy);
    final transformedPolygon = polygon.transform(transform);

    final path = transformedPolygon.path;
    if (handleFillColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = handleFillColor
          ..style = PaintingStyle.fill,
      );
    }
    if (handleBorderColor != null && handleBorderWidth != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = handleBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = handleBorderWidth / _averageScale(scale),
      );
    }
  }

  @override
  bool? hitTest(Offset position) {
    final center = alignment.alongSize(size);
    final polygon = Polygon.fromRect(
      Rect.fromCenter(
        center: center,
        width: handleWidth,
        height: handleHeight,
      ),
    );
    final transform = this.transform.clone();
    transform.translate(center.dx, center.dy);
    transform.scale(1 / scale.dx, 1 / scale.dy);
    transform.translate(-center.dx, -center.dy);
    final transformedPolygon = polygon.transform(transform);
    return transformedPolygon.contains(position);
  }

  static double _averageScale(Offset scale) {
    return (scale.dx + scale.dy) / 2;
  }

  @override
  bool shouldRepaint(covariant GizmoHandlePainter oldDelegate) {
    return oldDelegate.handleBorderColor != handleBorderColor ||
        oldDelegate.handleFillColor != handleFillColor ||
        oldDelegate.handleBorderWidth != handleBorderWidth ||
        oldDelegate.handleWidth != handleWidth ||
        oldDelegate.handleHeight != handleHeight ||
        oldDelegate.transform != transform ||
        oldDelegate.scale != scale;
  }
}
