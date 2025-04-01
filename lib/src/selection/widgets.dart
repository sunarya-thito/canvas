import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control.dart';
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
    _extraControls = [];
    // _extraControls = widget.selection
    //     .buildControls(
    //         editor: widget.editor,
    //         box: widget.selectionGroup.getTransformControlBox(
    //             parentTransform: widget.parentTransform))
    //     .toList();
  }

  @override
  void didUpdateWidget(covariant SelectionTransformControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {}
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

  SelectionMoveControlSession? _moveSession;

  String _toStringDouble(double d) {
    if (d.floorToDouble() == d) {
      return d.toStringAsFixed(0);
    }
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.selection.editorOffset,
      builder: (context, child) {
        var delta = widget.selection.editorOffset.value;
        var parentTransform = Matrix4.copy(widget.parentTransform);
        parentTransform.translate(delta.deltaX, delta.deltaY);
        var box = widget.selectionGroup
            .getTransformControlBox(parentTransform: parentTransform);
        Size size = box.size;
        Matrix4 transform = Matrix4.copy(box.transform);
        Polygon polygon = Polygon.fromRect(Offset.zero & size);
        polygon = polygon.transform(transform);
        final theme = CanvasTheme.of(context);
        final handleSize = Size(theme.transformControl.controlSize,
            theme.transformControl.controlSize);
        final topLeftHandleCenter = polygon.points[0];
        final topRightHandleCenter = polygon.points[1];
        final bottomRightHandleCenter = polygon.points[2];
        final bottomLeftHandleCenter = polygon.points[3];
        final topHandleCenter =
            (topLeftHandleCenter + topRightHandleCenter) * 0.5;
        final shear = box.shear;
        final flipHorizontal = size.width.isNegative;
        final flipVertical = size.height.isNegative;
        final editor = widget.editor;
        final boundsInfoRotation =
            (bottomLeftHandleCenter - bottomRightHandleCenter).direction;
        final boundsInfoSize =
            (bottomLeftHandleCenter - bottomRightHandleCenter).distance;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            GroupWidget(
              children: [
                Transform.translate(
                  offset: bottomLeftHandleCenter,
                  child: Transform.rotate(
                    angle: boundsInfoRotation + pi,
                    alignment: Alignment.topLeft,
                    child: IntrinsicHeight(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: boundsInfoSize,
                        ),
                        child: Center(
                          widthFactor: 0,
                          child: Container(
                            margin: EdgeInsets.only(top: 8),
                            decoration:
                                theme.transformControl.boundsInfoDecoraation,
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                                '${_toStringDouble(box.size.width)} x ${_toStringDouble(box.size.height)}'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            for (var item in widget.selectionGroup.selectedItems)
              Builder(
                builder: (context) {
                  var globalTransform =
                      widget.parentTransform * item.globalEditorTransform;
                  Polygon polygon =
                      Polygon.fromRect(Offset.zero & item.innerSize);
                  polygon = polygon.transform(globalTransform);
                  return DecoratedPolygon(
                    polygon: polygon,
                    strokeColor:
                        theme.transformControl.controlBoundaryBorderColor,
                    strokeWidth:
                        theme.transformControl.controlBoundaryBorderWidth,
                  );
                },
              ),
            GestureDetector(
              onTapUp: (details) {
                CanvasItemState item = editor.findItemAtPosition(
                    editor.globalToLocal(details.localPosition));
                editor.handleItemClick(item);
              },
              onPanStart: (details) {
                _moveSession = editor.startControlSession(
                    SelectionMoveControlSession(widget.selection, editor),
                    details.globalPosition);
              },
              onPanUpdate: (details) {
                if (_moveSession != null) {
                  _moveSession = editor.updateControlSession(
                      _moveSession!, details.globalPosition);
                }
              },
              onPanEnd: (details) {
                if (_moveSession != null) {
                  editor.endControlSession(_moveSession!);
                }
                print('panEnd');
              },
              onPanCancel: () {
                if (_moveSession != null) {
                  editor.cancelControlSession(_moveSession!);
                }
                print('panCancel');
              },
              child: DecoratedPolygon(
                polygon: polygon,
                strokeColor: theme.transformControl.controlBoundaryBorderColor,
                strokeWidth: theme.transformControl.controlBoundaryBorderWidth,
              ),
            ),
            // extra controls
            for (var control in _extraControls)
              ExtraTransformationControlWidget(control: control),
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
      },
    );
  }
}
