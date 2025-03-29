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
    return IgnorePointer(
      child: ListenableBuilder(
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
      ),
    );
  }
}

class SelectionTransformControlWidget extends StatefulWidget {
  final Matrix4 parentTransform;
  final SelectionGroup selectionGroup;

  const SelectionTransformControlWidget({
    super.key,
    required this.parentTransform,
    required this.selectionGroup,
  });

  @override
  State<SelectionTransformControlWidget> createState() =>
      _SelectionTransformControlWidgetState();
}

class _SelectionTransformControlWidgetState
    extends State<SelectionTransformControlWidget> {
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

  Widget _buildHandle(CanvasThemeData theme, Offset center, Size size,
      Offset shear, DirectionalCursor cursor) {
    Polygon polygon = _createHandlePolygon(center, size, shear);
    return MouseRegion(
      cursor: cursor.rotateByAngle(rotationFromShear(shear)).cursor,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          print('onTap: ${widget.selectionGroup}');
        },
        child: DecoratedPolygon(
          polygon: polygon,
          fillColor: theme.transformControl.controlColor,
          strokeColor: theme.transformControl.controlBorderColor,
          strokeWidth: theme.transformControl.controlBorderWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var box = widget.selectionGroup
        .getTransformControlBox(parentTransform: widget.parentTransform);
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
    final flipHorizontal = size.width.isNegative;
    final flipVertical = size.height.isNegative;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        IgnorePointer(
          child: DecoratedPolygon(
            polygon: polygon,
            strokeColor: theme.transformControl.controlBoundaryBorderColor,
            strokeWidth: theme.transformControl.controlBoundaryBorderWidth,
          ),
        ),
        // topLeft
        _buildHandle(
            theme,
            topLeftHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.topLeft
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
        // topRight
        _buildHandle(
            theme,
            topRightHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.topRight
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
        // bottomLeft
        _buildHandle(
            theme,
            bottomLeftHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.bottomLeft
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
        // bottomRight
        _buildHandle(
            theme,
            bottomRightHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.bottomRight
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
      ],
    );
  }
}
