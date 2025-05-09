import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control/extra.dart';
import 'package:canvas/src/editor/control/sessions/selection_move.dart';
import 'package:canvas/src/editor/selection/box.dart';
import 'package:canvas/src/editor/selection/selection.dart';
import 'package:canvas/src/editor/widget/data.dart';
import 'package:canvas/src/widget_util.dart';
import 'package:flutter/widgets.dart';

class SelectionWidget extends StatelessWidget {
  final CanvasEditor editor;
  final SelectionBox selectionBox;

  const SelectionWidget({
    super.key,
    required this.editor,
    required this.selectionBox,
  });

  @override
  Widget build(BuildContext context) {
    final canvasTheme = CanvasTheme.of(context);
    var viewportSize = CanvasEditorWidgetData.of(context).viewportSize;
    return IgnorePointer(
      child: ListenableBuilder(
        listenable:
            Listenable.merge([selectionBox.start, selectionBox.end, editor]),
        builder: (context, child) {
          Rect rect = selectionBox.rect;
          Offset topLeft =
              viewportLocalToGlobal(editor, viewportSize, rect.topLeft);
          Offset bottomRight =
              viewportLocalToGlobal(editor, viewportSize, rect.bottomRight);
          double minX = min(topLeft.dx, bottomRight.dx);
          double minY = min(topLeft.dy, bottomRight.dy);
          return Transform.translate(
            offset: Offset(minX, minY),
            child: Container(
              width: (bottomRight.dx - topLeft.dx).abs(),
              height: (bottomRight.dy - topLeft.dy).abs(),
              decoration: canvasTheme.viewport.selectionDecoration,
            ),
          );
        },
      ),
    );
  }
}

class SelectionTransformControlWidget extends StatefulWidget {
  final CanvasEditor editor;
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
    for (var item in widget.selectionGroup.items) {
      item.addListener(_update);
    }
  }

  @override
  void didUpdateWidget(covariant SelectionTransformControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      for (var item in oldWidget.selectionGroup.items) {
        item.removeListener(_update);
      }
      for (var item in widget.selectionGroup.items) {
        item.addListener(_update);
      }
    }
  }

  void _update() {
    setState(() {});
  }

  @override
  void dispose() {
    for (var item in widget.selectionGroup.items) {
      item.removeListener(_update);
    }
    super.dispose();
  }

  List<Offset> _fromRect(Rect rect) {
    return [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
  }

  List<Offset> _transform(List<Offset> points, Matrix4 transform) {
    return points.map((point) {
      return transformOffset(point, transform);
    }).toList();
  }

  List<Offset> _createDiagonalHandlePolygon(
      Offset center, Size size, Offset shear,
      {EdgeInsets? expand,
      bool flipHorizontal = false,
      bool flipVertical = false}) {
    Matrix4 matrix = Matrix4.identity();
    Offset origin = size.center(Offset.zero);
    matrix.translate(center.dx, center.dy);
    matrix.translate(-origin.dx, -origin.dy);
    matrix = matrix * computeOrigin(computeShearMatrix(shear), origin);
    double top = expand == null ? 0 : -expand.top;
    double left = expand == null ? 0 : -expand.left;
    double width = size.width + (expand?.horizontal ?? 0);
    double height = size.height + (expand?.vertical ?? 0);
    // Polygon polygon = Polygon.fromRect(Offset(left, top) & Size(width, height));
    List<Offset> points = [
      Offset(left, top),
      Offset(left + width, top),
      Offset(left + width, top + height),
      Offset(left, top + height),
    ];
    // polygon = polygon.transform(matrix);
    points = _transform(points, matrix);
    return points;
  }

  List<Offset> _createHandlePolygon(
      Offset center, Size size, Size itemSize, Offset shear, Axis direction,
      {EdgeInsets? expand}) {
    Matrix4 matrix = Matrix4.identity();
    Size handleSize = direction == Axis.vertical
        ? Size(size.width, itemSize.height * widget.zoom)
        : Size(itemSize.width * widget.zoom, size.height);
    Offset origin = handleSize.center(Offset.zero);
    matrix.translate(center.dx, center.dy);
    matrix = matrix * computeOrigin(computeShearMatrix(shear), origin);
    matrix.translate(-origin.dx, -origin.dy);
    double top = expand == null ? 0 : -expand.top;
    double left = expand == null ? 0 : -expand.left;
    double width = handleSize.width + (expand?.horizontal ?? 0);
    double height = handleSize.height + (expand?.vertical ?? 0);
    // Polygon polygon = Polygon.fromRect(Offset(left, top) & Size(width, height));
    // polygon = polygon.transform(matrix);
    // return polygon;
    List<Offset> points = _fromRect(Offset(left, top) & Size(width, height));
    points = _transform(points, matrix);
    return points;
  }

  Widget _buildDiagonalHandle(CanvasThemeData theme, Offset center, Size size,
      Offset shear, DirectionalCursor cursor, double rotation,
      {EdgeInsets? expand,
      bool fill = true,
      bool flipHorizontal = false,
      bool flipVertical = false}) {
    List<Offset> polygon = _createDiagonalHandlePolygon(
      center,
      size,
      shear,
      expand: expand,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );
    return MouseRegion(
      cursor: cursor.rotateByAngle(rotation).cursor,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          print('onTap: ${widget.selectionGroup}');
        },
        onPanStart: (details) {
          _totalDelta = Offset.zero;
        },
        onPanUpdate: (details) {
          _totalDelta += details.delta;
          print(
              'onPanUpdate: ${rotatePoint(_totalDelta, rotation)}, rotation: ${rotation * 180 / pi}');
        },
        child: widget.selection.editorDragOffset.value.delta == Offset.zero
            ? DecoratedPolygon(
                polygon: polygon,
                fillColor: fill ? theme.transformControl.controlColor : null,
                strokeColor:
                    fill ? theme.transformControl.controlBorderColor : null,
                strokeWidth:
                    fill ? theme.transformControl.controlBorderWidth : 0,
              )
            : null,
      ),
    );
  }

  Offset _totalDelta = Offset.zero;

  Widget _buildHandle(
      CanvasThemeData theme,
      Offset center,
      Size size,
      Size itemSize,
      Offset shear,
      Axis direction,
      DirectionalCursor cursor,
      double rotation,
      {EdgeInsets? expand,
      bool fill = false}) {
    List<Offset> polygon = _createHandlePolygon(
        center, size, itemSize, shear, direction,
        expand: expand);
    return MouseRegion(
      cursor: cursor.rotateByAngle(rotation).cursor,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanStart: (details) {
          _totalDelta = Offset.zero;
        },
        onPanUpdate: (details) {
          _totalDelta += details.delta;
          print(
              'onPanUpdate: ${rotatePoint(_totalDelta, rotation)}, rotation: ${rotation * 180 / pi}');
        },
        child: DecoratedPolygon(
          polygon: polygon,
          fillColor: fill ? theme.transformControl.controlColor : null,
          strokeColor: fill ? theme.transformControl.controlBorderColor : null,
          strokeWidth: fill ? theme.transformControl.controlBorderWidth : 0,
        ),
      ),
    );
  }

  String _toStringDouble(double d) {
    if (d.floorToDouble() == d) {
      return d.toStringAsFixed(0);
    }
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.selection.editorDragOffset,
        ...widget.selectionGroup.items,
      ]),
      builder: (context, child) {
        var delta = widget.selection.editorDragOffset.value;
        var parentTransform = Matrix4.copy(widget.parentTransform);
        parentTransform.translate(delta.deltaX, delta.deltaY);
        var box = widget.selectionGroup
            .getTransformControlBox(parentTransform: parentTransform);
        Size size = box.size;
        Matrix4 transform = Matrix4.copy(box.transform);
        // Polygon polygon = Polygon.fromRect(Offset.zero & size);
        // polygon = polygon.transform(transform);
        List<Offset> points = _fromRect(Offset.zero & size);
        points = _transform(points, transform);
        final theme = CanvasTheme.of(context);
        final handleSize = Size(theme.transformControl.controlSize,
            theme.transformControl.controlSize);
        final topLeftHandleCenter = points[0];
        final topRightHandleCenter = points[1];
        final bottomRightHandleCenter = points[2];
        final bottomLeftHandleCenter = points[3];
        final topHandleCenter =
            (topLeftHandleCenter + topRightHandleCenter) * 0.5;
        final shear = computeShearFromMatrix(box.transform);
        final flipHorizontal = size.width.isNegative;
        final flipVertical = size.height.isNegative;
        final editor = widget.editor;
        var rotationTestStart = Offset.zero;
        var rotationTest = Offset(1, 0);
        rotationTest = transformOffset(rotationTest, transform);
        rotationTestStart = transformOffset(rotationTestStart, transform);
        var rotation = -(rotationTest - rotationTestStart).direction;

        int rotationAdjustment =
            (wrapRotation(rotation + pi / 4) / (pi / 2)).floor() % 4;

        Offset alwaysBottomCenter;
        double boundsInfoSize;
        if (rotationAdjustment == 0) {
          alwaysBottomCenter = flipVertical
              ? flipHorizontal
                  ? topRightHandleCenter
                  : topLeftHandleCenter
              : flipHorizontal
                  ? bottomRightHandleCenter
                  : bottomLeftHandleCenter;
          boundsInfoSize =
              (bottomLeftHandleCenter - bottomRightHandleCenter).distance;
        } else if (rotationAdjustment == 1) {
          alwaysBottomCenter = flipVertical
              ? flipHorizontal
                  ? bottomRightHandleCenter
                  : bottomLeftHandleCenter
              : flipHorizontal
                  ? topRightHandleCenter
                  : topLeftHandleCenter;
          boundsInfoSize =
              (topLeftHandleCenter - bottomLeftHandleCenter).distance;
        } else if (rotationAdjustment == 2) {
          alwaysBottomCenter = flipVertical
              ? flipHorizontal
                  ? bottomLeftHandleCenter
                  : bottomRightHandleCenter
              : flipHorizontal
                  ? topLeftHandleCenter
                  : topRightHandleCenter;
          boundsInfoSize =
              (topRightHandleCenter - topLeftHandleCenter).distance;
        } else {
          alwaysBottomCenter = flipVertical
              ? flipHorizontal
                  ? topLeftHandleCenter
                  : topRightHandleCenter
              : flipHorizontal
                  ? bottomLeftHandleCenter
                  : bottomRightHandleCenter;
          boundsInfoSize =
              (bottomRightHandleCenter - topRightHandleCenter).distance;
        }
        return Stack(
          fit: StackFit.passthrough,
          children: [
            if (widget.selection.editorDragOffset.value.delta == Offset.zero)
              GroupWidget(
                children: [
                  Transform.translate(
                    offset: alwaysBottomCenter,
                    child: Transform.rotate(
                      angle: -rotation + (rotationAdjustment * pi / 2),
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
                                '${_toStringDouble(box.size.width)} x ${_toStringDouble(box.size.height)}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            for (var item in widget.selectionGroup.items)
              Builder(
                builder: (context) {
                  var globalTransform = widget.parentTransform *
                      item.computeEditorGlobalTransform();
                  // Polygon polygon = Polygon.fromRect(Offset.zero & item.size);
                  // polygon = polygon.transform(globalTransform);
                  List<Offset> polygonPoints =
                      _fromRect(Offset.zero & item.size);
                  polygonPoints = _transform(polygonPoints, globalTransform);
                  return widget.selection.editorDragOffset.value.delta ==
                          Offset.zero
                      ? DecoratedPolygon(
                          polygon: polygonPoints,
                          strokeColor:
                              theme.transformControl.controlBoundaryBorderColor,
                          strokeWidth:
                              theme.transformControl.controlBoundaryBorderWidth,
                        )
                      : SizedBox.shrink();
                },
              ),
            GestureDetector(
              onTapDown: (details) {
                final editorData = CanvasEditorWidgetData.find(context);
                CanvasItemState? item = editor.findItemAt(viewportGlobalToLocal(
                    editor,
                    editorData.viewportSize,
                    editorData.globalToLocal(details.globalPosition)));
                if (item != null) {
                  editor.handleItemClick(item);
                }
              },
              onPanStart: (details) {
                final editorData = CanvasEditorWidgetData.find(context);
                editor.startControlSession(
                    SelectionMoveControlSession(selection: widget.selection),
                    editorData.globalToLocal(details.globalPosition),
                    editorData.viewportSize);
              },
              onPanUpdate: (details) {
                final editorData = CanvasEditorWidgetData.find(context);
                editor.updateControlSession(
                    editorData.globalToLocal(details.globalPosition),
                    editorData.viewportSize);
              },
              onPanEnd: (details) {
                editor.endControlSession();
              },
              onPanCancel: () {
                editor.cancelControlSession();
              },
              child:
                  widget.selection.editorDragOffset.value.delta == Offset.zero
                      ? DecoratedPolygon(
                          polygon: points,
                          strokeColor:
                              theme.transformControl.controlBoundaryBorderColor,
                          strokeWidth:
                              theme.transformControl.controlBoundaryBorderWidth,
                        )
                      : null,
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
              rotation,
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
              rotation,
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
              rotation,
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
              rotation,
            ),
            // rotate topLeft
            _buildDiagonalHandle(
              theme,
              topLeftHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.topRight
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
              expand: EdgeInsets.only(
                top: handleSize.height,
                left: handleSize.width,
              ),
              fill: false,
              flipHorizontal: flipHorizontal,
              flipVertical: flipVertical,
            ),
            // rotate topRight
            _buildDiagonalHandle(
              theme,
              topRightHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.bottomRight
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
              expand: EdgeInsets.only(
                top: handleSize.height,
                right: handleSize.width,
              ),
              fill: false,
              flipHorizontal: flipHorizontal,
              flipVertical: flipVertical,
            ),
            // rotate bottomLeft
            _buildDiagonalHandle(
              theme,
              bottomLeftHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.topLeft
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
              expand: EdgeInsets.only(
                bottom: handleSize.height,
                left: handleSize.width,
              ),
              fill: false,
              flipHorizontal: flipHorizontal,
              flipVertical: flipVertical,
            ),
            // rotate bottomRight
            _buildDiagonalHandle(
              theme,
              bottomRightHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.bottomLeft
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
              expand: EdgeInsets.only(
                bottom: handleSize.height,
                right: handleSize.width,
              ),
              fill: false,
              flipHorizontal: flipHorizontal,
              flipVertical: flipVertical,
            ),
            // topLeft
            _buildDiagonalHandle(
              theme,
              topLeftHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.topLeft
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
            ),
            // topRight
            _buildDiagonalHandle(
              theme,
              topRightHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.topRight
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
            ),
            // bottomLeft
            _buildDiagonalHandle(
              theme,
              bottomLeftHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.bottomLeft
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
            ),
            // bottomRight
            _buildDiagonalHandle(
              theme,
              bottomRightHandleCenter,
              handleSize,
              shear,
              DirectionalCursor.bottomRight
                  .flip(horizontal: flipHorizontal, vertical: flipVertical),
              rotation,
            ),
          ],
        );
      },
    );
  }
}
