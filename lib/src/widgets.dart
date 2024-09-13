import 'dart:math';

import 'package:canvas/src/rendering.dart';
import 'package:flutter/material.dart';

abstract class CanvasItem extends Listenable {
  void onPressed();
  set transform(CanvasItemTransform value);
  CanvasItemTransform get transform;
  Widget build(BuildContext context);
  bool get selected;
  set selected(bool value);
}

abstract class CanvasItemAdapter extends CanvasItem with ChangeNotifier {
  CanvasItemTransform _transform;
  bool _selected;

  CanvasItemAdapter({
    CanvasItemTransform transform = CanvasItemTransform.defaultTransform,
    bool selected = false,
  })  : _transform = transform,
        _selected = selected;

  @override
  bool get selected => _selected;

  @override
  set selected(bool value) {
    if (_selected != value) {
      _selected = value;
      notifyListeners();
    }
  }

  @override
  CanvasItemTransform get transform => _transform;

  @override
  set transform(CanvasItemTransform value) {
    if (_transform != value) {
      _transform = value;
      notifyListeners();
    }
  }
}

class CanvasItemTransform {
  static const defaultTransform = CanvasItemTransform(
    position: Offset.zero,
    rotation: 0.0,
    size: Size.zero,
  );
  final Offset position;
  final double rotation;
  final Size size;

  const CanvasItemTransform({
    this.position = Offset.zero,
    this.rotation = 0.0,
    this.size = Size.zero,
  });

  @override
  bool operator ==(Object other) {
    return other is CanvasItemTransform &&
        other.position == position &&
        other.rotation == rotation &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(position, rotation, size);

  @override
  String toString() {
    return 'CanvasItemTransform(position: $position, rotation: $rotation, size: $size)';
  }

  CanvasItemTransform resize({
    Offset topLeftDelta = Offset.zero,
    Offset topDelta = Offset.zero,
    Offset topRightDelta = Offset.zero,
    Offset rightDelta = Offset.zero,
    Offset bottomRightDelta = Offset.zero,
    Offset bottomDelta = Offset.zero,
    Offset bottomLeftDelta = Offset.zero,
    Offset leftDelta = Offset.zero,
    bool uniform = false,
    bool keepAspectRatio = false,
  }) {
    if (uniform) {
      topLeftDelta =
          topLeftDelta + topRightDelta + bottomLeftDelta + bottomRightDelta;
      topDelta = topDelta + bottomDelta;
      topRightDelta =
          topRightDelta + topLeftDelta + bottomRightDelta + bottomLeftDelta;
      rightDelta = rightDelta + leftDelta;
      bottomRightDelta =
          bottomRightDelta + topLeftDelta + topRightDelta + bottomLeftDelta;
      bottomDelta = bottomDelta + topDelta;
      bottomLeftDelta =
          bottomLeftDelta + topRightDelta + bottomRightDelta + topLeftDelta;
      leftDelta = leftDelta + rightDelta;
    }
    Rect rect = position & size;
    double minX = rect.left;
    double minY = rect.top;
    double maxX = rect.right;
    double maxY = rect.bottom;

    minX += leftDelta.dx + topLeftDelta.dx + bottomLeftDelta.dx;
    minY += topDelta.dy + topLeftDelta.dy + topRightDelta.dy;
    maxX += rightDelta.dx + topRightDelta.dx + bottomRightDelta.dx;
    maxY += bottomDelta.dy + bottomRightDelta.dy + bottomLeftDelta.dy;

    if (keepAspectRatio) {
      double width = maxX - minX;
      double height = maxY - minY;
      double aspectRatio = width / height;
      double newWidth = width + leftDelta.dx + rightDelta.dx;
      double newHeight = newWidth / aspectRatio;
      double newMinY = minY + topDelta.dy + topLeftDelta.dy;
      double newMaxY = newMinY + newHeight;
      minY = newMinY;
      maxY = newMaxY;
    }

    return CanvasItemTransform(
      position: Offset(minX, minY),
      rotation: rotation,
      size: Size(max(0, maxX - minX), max(0, maxY - minY)),
    );
  }
}

double degToRad(double deg) => deg * (pi / 180.0);
double radToDeg(double rad) => rad / (pi / 180.0);

class CanvasItemWidget extends StatelessWidget {
  final Widget child;
  final CanvasItemTransform transform;
  final Alignment anchor;

  const CanvasItemWidget({
    super.key,
    required this.child,
    required this.transform,
    this.anchor = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return PositionedCanvasItem(
      bounds: transform.position & transform.size,
      rotation: transform.rotation,
      anchor: anchor,
      child: SizedBox.fromSize(
        size: transform.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: transform.rotation,
                alignment: anchor,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CanvasViewport extends StatelessWidget {
  final double scale;
  final Offset offset;
  final List<CanvasItem> items;

  const CanvasViewport({
    super.key,
    required this.items,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        CanvasTheme.maybeOf(context) ?? CanvasThemeData.defaultTheme();
    return CanvasTheme(
      data: theme,
      child: ListenableBuilder(
        listenable: Listenable.merge(items),
        builder: (context, child) {
          List<Widget> children = [];
          for (var item in items) {
            children.add(
              CanvasItemWidget(
                transform: item.transform,
                child: item.build(context),
              ),
            );
          }
          for (var item in items) {
            children.add(
              CanvasItemGizmo(
                item: item,
                items: items,
                show: item.selected,
              ),
            );
          }
          return CanvasStackViewport(
            scale: scale,
            offset: offset,
            children: children,
          );
        },
      ),
    );
  }
}

class CanvasItemGizmo extends StatelessWidget {
  final CanvasItem item;
  final List<CanvasItem> items;
  final bool show;
  final bool uniform;
  final bool keepAspectRatio;
  final bool showRotationHandle;

  const CanvasItemGizmo({
    super.key,
    required this.item,
    required this.items,
    this.show = true,
    this.uniform = false,
    this.keepAspectRatio = false,
    this.showRotationHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CanvasTheme.of(context);
    var rect = (item.transform.position & item.transform.size);
    final anchorOffset = rect.topLeft + rect.size.center(Offset.zero);
    final topLeftGizmoOffset = rotatePoint(
      rect.topLeft,
      item.transform.rotation,
      anchorOffset,
    );
    final topRightGizmoOffset = rotatePoint(
      rect.topRight,
      item.transform.rotation,
      anchorOffset,
    );
    final bottomLeftGizmoOffset = rotatePoint(
      rect.bottomLeft,
      item.transform.rotation,
      anchorOffset,
    );
    final bottomRightGizmoOffset = rotatePoint(
      rect.bottomRight,
      item.transform.rotation,
      anchorOffset,
    );
    final topGizmoOffset = rotatePoint(
      rect.topCenter,
      item.transform.rotation,
      anchorOffset,
    );
    final bottomGizmoOffset = rotatePoint(
      rect.bottomCenter,
      item.transform.rotation,
      anchorOffset,
    );
    final leftGizmoOffset = rotatePoint(
      rect.centerLeft,
      item.transform.rotation,
      anchorOffset,
    );
    final rightGizmoOffset = rotatePoint(
      rect.centerRight,
      item.transform.rotation,
      anchorOffset,
    );
    final rotationHandleLineOffset = rotatePoint(
      rect.topCenter +
          Offset(0,
              -theme.gizmoMicroSize.height - theme.gizmoMicroSize.height / 2),
      item.transform.rotation,
      anchorOffset,
    );
    final rotationHandleOffset = rotatePoint(
      rect.topCenter +
          Offset(0,
              -theme.gizmoMicroSize.height - theme.gizmoRotationHandleLength),
      item.transform.rotation,
      anchorOffset,
    );
    return GizmoCanvasItem(
        child: Stack(
      children: [
        // gizmo
        Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            onPanUpdate: (details) {
              for (var item in items) {
                if (item.selected) {
                  item.transform = CanvasItemTransform(
                    position: item.transform.position + details.delta,
                    rotation: item.transform.rotation,
                    size: item.transform.size,
                  );
                }
              }
            },
            child: Transform.rotate(
              angle: item.transform.rotation,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  item.onPressed();
                },
                child: show
                    ? Container(
                        decoration: theme.gizmoDecoration,
                      )
                    : Container(),
              ),
            ),
          ),
        ),
        if (show) ...[
          // top left gizmo
          Positioned(
            left: topLeftGizmoOffset.dx - theme.gizmoMacroSize.width / 2,
            top: topLeftGizmoOffset.dy - theme.gizmoMacroSize.height / 2,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                Offset delta = details.delta;
                for (var item in items) {
                  if (item.selected) {
                    // resize top left
                    item.transform = item.transform.resize(
                      topLeftDelta: delta,
                      uniform: uniform,
                      keepAspectRatio: keepAspectRatio,
                    );
                  }
                }
              },
              child: Transform.rotate(
                angle: item.transform.rotation,
                child: Container(
                  width: theme.gizmoMacroSize.width,
                  height: theme.gizmoMacroSize.height,
                  decoration: theme.gizmoMicroDecoration,
                ),
              ),
            ),
          ),
          // top right gizmo
          Positioned(
            left: topRightGizmoOffset.dx - theme.gizmoMacroSize.width / 2,
            top: topRightGizmoOffset.dy - theme.gizmoMacroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMacroSize.width,
                height: theme.gizmoMacroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // bottom left gizmo
          Positioned(
            left: bottomLeftGizmoOffset.dx - theme.gizmoMacroSize.width / 2,
            top: bottomLeftGizmoOffset.dy - theme.gizmoMacroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMacroSize.width,
                height: theme.gizmoMacroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // bottom right gizmo
          Positioned(
            left: bottomRightGizmoOffset.dx - theme.gizmoMacroSize.width / 2,
            top: bottomRightGizmoOffset.dy - theme.gizmoMacroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMacroSize.width,
                height: theme.gizmoMacroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // micro top gizmo
          Positioned(
            left: topGizmoOffset.dx - theme.gizmoMicroSize.width / 2,
            top: topGizmoOffset.dy - theme.gizmoMicroSize.height / 2,
            child: GestureDetector(
              onPanUpdate: (details) {
                Offset delta = details.delta;
                for (var item in items) {
                  if (item.selected) {
                    // resize top
                    item.transform = item.transform.resize(
                      topDelta: delta,
                      uniform: uniform,
                      keepAspectRatio: keepAspectRatio,
                    );
                  }
                }
              },
              child: Transform.rotate(
                angle: item.transform.rotation,
                child: Container(
                  width: theme.gizmoMicroSize.width,
                  height: theme.gizmoMicroSize.height,
                  decoration: theme.gizmoMicroDecoration,
                ),
              ),
            ),
          ),
          // micro bottom gizmo
          Positioned(
            left: bottomGizmoOffset.dx - theme.gizmoMicroSize.width / 2,
            top: bottomGizmoOffset.dy - theme.gizmoMicroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMicroSize.width,
                height: theme.gizmoMicroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // micro left gizmo
          Positioned(
            left: leftGizmoOffset.dx - theme.gizmoMicroSize.width / 2,
            top: leftGizmoOffset.dy - theme.gizmoMicroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMicroSize.width,
                height: theme.gizmoMicroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // micro right gizmo
          Positioned(
            left: rightGizmoOffset.dx - theme.gizmoMicroSize.width / 2,
            top: rightGizmoOffset.dy - theme.gizmoMicroSize.height / 2,
            child: Transform.rotate(
              angle: item.transform.rotation,
              child: Container(
                width: theme.gizmoMicroSize.width,
                height: theme.gizmoMicroSize.height,
                decoration: theme.gizmoMicroDecoration,
              ),
            ),
          ),
          // rotation handle line
          if (showRotationHandle) ...[
            Positioned(
              left: rotationHandleLineOffset.dx,
              top: rotationHandleLineOffset.dy -
                  theme.gizmoRotationHandleLength / 2,
              child: Transform.rotate(
                angle: item.transform.rotation,
                child: Container(
                  height: theme.gizmoRotationHandleLength,
                  width: 0,
                  decoration: BoxDecoration(
                    border: Border(
                      left: theme.gizmoRotationHandleBorder,
                    ),
                  ),
                ),
              ),
            ),
            // rotation handle
            Positioned(
              left: rotationHandleOffset.dx -
                  theme.gizmoRotationHandleSize.width / 2,
              top: rotationHandleOffset.dy -
                  theme.gizmoRotationHandleSize.height / 2,
              child: Transform.rotate(
                angle: item.transform.rotation,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    var position = (context.findRenderObject() as RenderBox)
                        .globalToLocal(details.globalPosition);
                    var relativePosition = position - anchorOffset;
                    // find the angle
                    var angle = atan2(relativePosition.dy, relativePosition.dx);
                    var angleDeg = radToDeg(angle) + 90;
                    // snap the angle deg when close to 0, 45, 90, 135, 180, 225, 270, 315, 360
                    angleDeg = snapRotationToClosest(angleDeg, 5);
                    var angleDelta =
                        angleDeg - radToDeg(item.transform.rotation);
                    for (var item in items) {
                      if (item.selected) {
                        item.transform = CanvasItemTransform(
                          position: item.transform.position,
                          rotation:
                              item.transform.rotation + degToRad(angleDelta),
                          size: item.transform.size,
                        );
                      }
                    }
                  },
                  child: Container(
                    width: theme.gizmoRotationHandleSize.width,
                    height: theme.gizmoRotationHandleSize.height,
                    decoration: theme.gizmoRotationDecoration,
                  ),
                ),
              ),
            ),
          ]
        ]
      ],
    ));
  }
}

List<double> _snapAngles = [
  0,
  45,
  90,
  135,
  180,
  225,
  270,
  315,
  360,
];
double snapRotationToClosest(double angleDeg, [double snapDistance = 5]) {
  angleDeg = angleDeg % 360;
  // snap the angle deg when close to 0, 45, 90, 135, 180, 225, 270, 315, 360
  for (var snapAngle in _snapAngles) {
    final distance = (angleDeg - snapAngle).abs();
    if (distance < snapDistance) {
      return snapAngle;
    }
  }
  return angleDeg;
}

class CanvasThemeData {
  final Decoration gizmoMicroDecoration;
  final Decoration gizmoMacroDecoration;
  final Decoration gizmoDecoration;
  final Decoration gizmoRotationDecoration;
  final BorderSide gizmoRotationHandleBorder;
  final Size gizmoMicroSize;
  final Size gizmoMacroSize;
  final double gizmoRotationHandleLength;
  final Size gizmoRotationHandleSize;

  const CanvasThemeData({
    required this.gizmoMicroDecoration,
    required this.gizmoMacroDecoration,
    required this.gizmoDecoration,
    required this.gizmoRotationDecoration,
    required this.gizmoRotationHandleBorder,
    this.gizmoMicroSize = const Size(10, 10),
    this.gizmoMacroSize = const Size(12, 12),
    this.gizmoRotationHandleLength = 20.0,
    this.gizmoRotationHandleSize = const Size(10, 10),
  });

  factory CanvasThemeData.defaultTheme() {
    return CanvasThemeData(
      gizmoMicroDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      gizmoMacroDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      gizmoDecoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      gizmoRotationDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.0),
        shape: BoxShape.circle,
      ),
      gizmoRotationHandleBorder: const BorderSide(
        color: Colors.black,
        width: 1.0,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CanvasThemeData &&
        other.gizmoMicroDecoration == gizmoMicroDecoration &&
        other.gizmoMacroDecoration == gizmoMacroDecoration &&
        other.gizmoDecoration == gizmoDecoration &&
        other.gizmoMicroSize == gizmoMicroSize &&
        other.gizmoMacroSize == gizmoMacroSize;
  }

  @override
  int get hashCode => Object.hash(
        gizmoMicroDecoration,
        gizmoMacroDecoration,
        gizmoDecoration,
        gizmoMicroSize,
        gizmoMacroSize,
      );

  @override
  String toString() {
    return 'CanvasThemeData('
        'gizmoMicroDecoration: $gizmoMicroDecoration, '
        'gizmoMacroDecoration: $gizmoMacroDecoration, '
        'gizmoDecoration: $gizmoDecoration, '
        'gizmoMicroSize: $gizmoMicroSize, '
        'gizmoMacroSize: $gizmoMacroSize'
        ')';
  }
}

class CanvasTheme extends InheritedTheme {
  final CanvasThemeData data;

  const CanvasTheme({
    super.key,
    required this.data,
    required Widget child,
  }) : super(child: child);

  static CanvasThemeData of(BuildContext context) {
    final CanvasTheme? canvasTheme =
        context.dependOnInheritedWidgetOfExactType<CanvasTheme>();
    assert(canvasTheme != null, 'No CanvasTheme found in context');
    return canvasTheme!.data;
  }

  static CanvasThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CanvasTheme>()?.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final CanvasTheme? ancestorTheme =
        context.findAncestorWidgetOfExactType<CanvasTheme>();
    return identical(this, ancestorTheme)
        ? child
        : CanvasTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(CanvasTheme oldWidget) => data != oldWidget.data;
}
