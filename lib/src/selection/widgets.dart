import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/extra.dart';
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
  final CanvasEditorHandler editor;
  final Matrix4 parentTransform;
  final Selection selection;
  final SelectionGroup selectionGroup;
  final double zoom;

  const SelectionTransformControlWidget({
    super.key,
    required this.parentTransform,
    required this.editor,
    required this.selection,
    required this.selectionGroup,
    required this.zoom,
  });

  @override
  State<SelectionTransformControlWidget> createState() =>
      _SelectionTransformControlWidgetState();
}

class _SelectionTransformControlWidgetState
    extends State<SelectionTransformControlWidget> {
  late List<ExtraTransformationControl> _extraControls;

  @override
  void initState() {
    super.initState();
    _extraControls = widget.selection
        .buildControls(
            editor: widget.editor, parentTransform: widget.parentTransform)
        .toList();
    for (var control in _extraControls) {
      control.addListener(_update);
    }
  }

  @override
  void didUpdateWidget(covariant SelectionTransformControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      for (var control in _extraControls) {
        control.removeListener(_update);
      }
      _extraControls = widget.selection
          .buildControls(
              editor: widget.editor, parentTransform: widget.parentTransform)
          .toList();
      for (var control in _extraControls) {
        control.addListener(_update);
      }
    }
  }

  @override
  void dispose() {
    for (var control in _extraControls) {
      control.removeListener(_update);
    }
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  Polygon _createDiagonalHandlePolygon(Offset center, Size size, Offset shear,
      {EdgeInsets? expand}) {
    Matrix4 matrix = Matrix4.identity();
    Offset origin = size.center(Offset.zero);
    matrix.translate(center.dx, center.dy);
    matrix = computeShearMatrix(shear.dx, shear.dy, parent: matrix);
    matrix.translate(-origin.dx, -origin.dy);
    double top = expand == null ? 0 : -expand.top;
    double left = expand == null ? 0 : -expand.left;
    double width = size.width + (expand?.horizontal ?? 0);
    double height = size.height + (expand?.vertical ?? 0);
    Polygon polygon = Polygon.fromRect(Offset(left, top) & Size(width, height));
    polygon = polygon.transform(matrix);
    return polygon;
  }

  Polygon _createHandlePolygon(
      Offset center, Size size, Size itemSize, Offset shear, Axis direction,
      {EdgeInsets? expand}) {
    Matrix4 matrix = Matrix4.identity();
    Size handleSize = direction == Axis.vertical
        ? Size(size.width, itemSize.height * widget.zoom)
        : Size(itemSize.width * widget.zoom, size.height);
    Offset origin = handleSize.center(Offset.zero);
    matrix.translate(center.dx, center.dy);
    matrix = computeShearMatrix(shear.dx, shear.dy, parent: matrix);
    matrix.translate(-origin.dx, -origin.dy);
    double top = expand == null ? 0 : -expand.top;
    double left = expand == null ? 0 : -expand.left;
    double width = handleSize.width + (expand?.horizontal ?? 0);
    double height = handleSize.height + (expand?.vertical ?? 0);
    Polygon polygon = Polygon.fromRect(Offset(left, top) & Size(width, height));
    polygon = polygon.transform(matrix);
    return polygon;
  }

  Widget _buildDiagonalHandle(CanvasThemeData theme, Offset center, Size size,
      Offset shear, DirectionalCursor cursor,
      {EdgeInsets? expand, bool fill = true}) {
    Polygon polygon =
        _createDiagonalHandlePolygon(center, size, shear, expand: expand);
    return MouseRegion(
      cursor: cursor.rotateByAngle(rotationFromShear(shear)).cursor,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          print('onTap: ${widget.selectionGroup}');
        },
        onPanUpdate: (details) {},
        child: DecoratedPolygon(
          polygon: polygon,
          fillColor: fill ? theme.transformControl.controlColor : null,
          strokeColor: fill ? theme.transformControl.controlBorderColor : null,
          strokeWidth: fill ? theme.transformControl.controlBorderWidth : 0,
        ),
      ),
    );
  }

  Widget _buildHandle(CanvasThemeData theme, Offset center, Size size,
      Size itemSize, Offset shear, Axis direction, DirectionalCursor cursor,
      {EdgeInsets? expand, bool fill = false}) {
    Polygon polygon = _createHandlePolygon(
        center, size, itemSize, shear, direction,
        expand: expand);
    return MouseRegion(
      cursor: cursor.rotateByAngle(rotationFromShear(shear)).cursor,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          print('onTap: ${widget.selectionGroup}');
        },
        onPanUpdate: (details) {},
        child: DecoratedPolygon(
          polygon: polygon,
          fillColor: fill ? theme.transformControl.controlColor : null,
          strokeColor: fill ? theme.transformControl.controlBorderColor : null,
          strokeWidth: fill ? theme.transformControl.controlBorderWidth : 0,
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
    final topHandleCenter = (topLeftHandleCenter + topRightHandleCenter) * 0.5;
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
        // top shear
        _buildHandle(
          theme,
          topHandleCenter,
          handleSize,
          size,
          shear,
          Axis.horizontal,
          DirectionalCursor.left
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(top: handleSize.height),
        ),
        // bottom shear
        _buildHandle(
          theme,
          (bottomLeftHandleCenter + bottomRightHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.horizontal,
          DirectionalCursor.right
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(bottom: handleSize.height),
        ),
        // left shear
        _buildHandle(
          theme,
          (topLeftHandleCenter + bottomLeftHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.vertical,
          DirectionalCursor.top
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(left: handleSize.width),
        ),
        // right shear
        _buildHandle(
          theme,
          (topRightHandleCenter + bottomRightHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.vertical,
          DirectionalCursor.bottom
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(right: handleSize.width),
        ),
        // top
        _buildHandle(
          theme,
          topHandleCenter,
          handleSize,
          size,
          shear,
          Axis.horizontal,
          DirectionalCursor.top
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
        ),
        // bottom
        _buildHandle(
          theme,
          (bottomLeftHandleCenter + bottomRightHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.horizontal,
          DirectionalCursor.bottom
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
        ),
        // left
        _buildHandle(
          theme,
          (topLeftHandleCenter + bottomLeftHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.vertical,
          DirectionalCursor.left
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
        ),
        // right
        _buildHandle(
          theme,
          (topRightHandleCenter + bottomRightHandleCenter) * 0.5,
          handleSize,
          size,
          shear,
          Axis.vertical,
          DirectionalCursor.right
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
        ),
        // rotate topLeft
        _buildDiagonalHandle(
          theme,
          topLeftHandleCenter,
          handleSize,
          shear,
          DirectionalCursor.topRight
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(
            top: handleSize.height,
            left: handleSize.width,
          ),
          fill: false,
        ),
        // rotate topRight
        _buildDiagonalHandle(
          theme,
          topRightHandleCenter,
          handleSize,
          shear,
          DirectionalCursor.bottomRight
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(
            top: handleSize.height,
            right: handleSize.width,
          ),
          fill: false,
        ),
        // rotate bottomLeft
        _buildDiagonalHandle(
          theme,
          bottomLeftHandleCenter,
          handleSize,
          shear,
          DirectionalCursor.topLeft
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(
            bottom: handleSize.height,
            left: handleSize.width,
          ),
          fill: false,
        ),
        // rotate bottomRight
        _buildDiagonalHandle(
          theme,
          bottomRightHandleCenter,
          handleSize,
          shear,
          DirectionalCursor.bottomLeft
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
          expand: EdgeInsets.only(
            bottom: handleSize.height,
            right: handleSize.width,
          ),
          fill: false,
        ),
        // topLeft
        _buildDiagonalHandle(
          theme,
          topLeftHandleCenter,
          handleSize,
          shear,
          DirectionalCursor.topLeft
              .flip(horizontal: flipHorizontal, vertical: flipVertical),
        ),
        // topRight
        _buildDiagonalHandle(
            theme,
            topRightHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.topRight
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
        // bottomLeft
        _buildDiagonalHandle(
            theme,
            bottomLeftHandleCenter,
            handleSize,
            shear,
            DirectionalCursor.bottomLeft
                .flip(horizontal: flipHorizontal, vertical: flipVertical)),
        // bottomRight
        _buildDiagonalHandle(
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
