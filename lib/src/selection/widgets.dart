import 'package:canvas/canvas.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

class SelectionWidget extends StatelessWidget {
  final SelectionBox selectionBox;

  const SelectionWidget({
    super.key,
    required this.selectionBox,
  });

  @override
  Widget build(BuildContext context) {
    final canvasTheme = CanvasTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([selectionBox.start, selectionBox.end]),
      builder: (context, child) {
        Rect rect = selectionBox.rect;
        return Transform.translate(
          offset: rect.topLeft,
          child: Container(
            width: rect.width,
            height: rect.height,
            decoration: canvasTheme.viewport.selectionDecoration,
          ),
        );
      },
    );
  }
}

class SelectionTransformControlWidget extends StatelessWidget {
  final Matrix4 parentTransform;
  final SelectionGroup selectionGroup;

  const SelectionTransformControlWidget({
    super.key,
    required this.parentTransform,
    required this.selectionGroup,
  });

  Polygon _createHandlePolygon(Offset center, Size size, Offset shear) {
    Matrix4 matrix = Matrix4.identity();
    Offset origin = size.center(Offset.zero);
    matrix.translate(center.dx, center.dy);
    matrix = computeShearMatrix(shear.dx, shear.dy, parent: matrix);
    matrix.translate(-origin.dx, -origin.dy);
    Polygon polygon = Polygon.fromRect(Offset.zero & size);
    polygon = polygon.transform(matrix);
    return polygon;
  }

  @override
  Widget build(BuildContext context) {
    var box =
        selectionGroup.getTransformControlBox(parentTransform: parentTransform);
    Size size = box.size;
    Matrix4 transform = box.transform;
    Polygon polygon = Polygon.fromRect(Offset.zero & size);
    polygon = polygon.transform(transform);
    final theme = CanvasTheme.of(context);
    final handleSize = Size(
        theme.transformControl.controlSize, theme.transformControl.controlSize);
    final topLeftHandleCenter = polygon.points[0];
    final topRightHandleCenter = polygon.points[1];
    final bottomRightHandleCenter = polygon.points[2];
    final bottomLeftHandleCenter = polygon.points[3];
    final shear = box.shear;

    final topLeftHandlePolygon = _createHandlePolygon(
      topLeftHandleCenter,
      handleSize,
      shear,
    );
    final topRightHandlePolygon = _createHandlePolygon(
      topRightHandleCenter,
      handleSize,
      shear,
    );
    final bottomLeftHandlePolygon = _createHandlePolygon(
      bottomLeftHandleCenter,
      handleSize,
      shear,
    );
    final bottomRightHandlePolygon = _createHandlePolygon(
      bottomRightHandleCenter,
      handleSize,
      shear,
    );

    return GroupWidget(size: Size.zero, children: [
      DecoratedPolygon(
        polygon: polygon,
        strokeColor: theme.transformControl.controlBoundaryBorderColor,
        strokeWidth: theme.transformControl.controlBoundaryBorderWidth,
      ),
      // topLeft
      DecoratedPolygon(
        polygon: topLeftHandlePolygon,
        fillColor: theme.transformControl.controlColor,
        strokeColor: theme.transformControl.controlBorderColor,
        strokeWidth: theme.transformControl.controlBorderWidth,
      ),
      // topRight
      DecoratedPolygon(
        polygon: topRightHandlePolygon,
        fillColor: theme.transformControl.controlColor,
        strokeColor: theme.transformControl.controlBorderColor,
        strokeWidth: theme.transformControl.controlBorderWidth,
      ),
      // bottomLeft
      DecoratedPolygon(
        polygon: bottomLeftHandlePolygon,
        fillColor: theme.transformControl.controlColor,
        strokeColor: theme.transformControl.controlBorderColor,
        strokeWidth: theme.transformControl.controlBorderWidth,
      ),
      // bottomRight
      DecoratedPolygon(
        polygon: bottomRightHandlePolygon,
        fillColor: theme.transformControl.controlColor,
        strokeColor: theme.transformControl.controlBorderColor,
        strokeWidth: theme.transformControl.controlBorderWidth,
      ),
    ]);
  }
}
