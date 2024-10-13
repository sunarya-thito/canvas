import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GroupWidget extends MultiChildRenderObjectWidget {
  final Size? size;
  final Clip clipBehavior;
  const GroupWidget({
    super.key,
    super.children,
    this.size,
    this.clipBehavior = Clip.none,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGroup(size: size);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGroup renderObject) {
    bool needsLayout = false;
    if (renderObject._size != size) {
      renderObject._size = size;
      needsLayout = true;
    }
    if (renderObject._clipBehavior != clipBehavior) {
      renderObject._clipBehavior = clipBehavior;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
  }
}

class GroupParentData extends ContainerBoxParentData<RenderBox> {}

class RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  static const double _bigSize = 999999999999999;
  static const BoxConstraints _bigConstraints = BoxConstraints(
    maxWidth: _bigSize,
    maxHeight: _bigSize,
  );
  Size? _size;
  Clip _clipBehavior;
  RenderGroup({
    List<RenderBox>? children,
    Size? size,
    Clip clipBehavior = Clip.none,
  })  : _clipBehavior = clipBehavior,
        _size = size,
        super() {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  void performLayout() {
    var localSize = _size;
    if (localSize == null) {
      size = constraints.biggest;
    } else {
      size = localSize.abs();
    }
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      child.layout(_bigConstraints);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      final childHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (childHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      if (_clipBehavior != Clip.none) {
        context.pushClipRect(
          needsCompositing,
          offset + childParentData.offset,
          Offset.zero & (_size ?? size),
          (context, offset) {
            context.paintChild(child!, offset);
          },
          clipBehavior: _clipBehavior,
        );
      } else {
        context.paintChild(child, offset + childParentData.offset);
      }
      child = childParentData.nextSibling;
    }
  }
}

class PanGesture extends StatefulWidget {
  final bool enable;
  final void Function(DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final void Function()? onPanCancel;
  final Widget? child;
  final HitTestBehavior behavior;

  const PanGesture({
    super.key,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.enable = true,
    this.behavior = HitTestBehavior.translucent,
    this.child,
  });

  @override
  State<PanGesture> createState() => _PanGestureState();
}

class _PanGestureState extends State<PanGesture> {
  final FocusNode _focusNode = FocusNode();
  bool _cancel = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          _cancel = true;
          widget.onPanCancel?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onPanStart: widget.enable
            ? (details) {
                _focusNode.requestFocus();
                _cancel = false;
                widget.onPanStart?.call(details);
              }
            : null,
        onPanUpdate: widget.enable
            ? (details) {
                if (_cancel) {
                  return;
                }
                widget.onPanUpdate?.call(details);
              }
            : null,
        onPanEnd: widget.enable
            ? (details) {
                if (_cancel) {
                  return;
                }
                widget.onPanEnd?.call(details);
              }
            : null,
        onPanCancel: widget.enable
            ? () {
                _cancel = true;
                widget.onPanCancel?.call();
              }
            : null,
        child: widget.child,
      ),
    );
  }
}

class MousePanGesture extends StatefulWidget {
  static const int primaryButton = kPrimaryButton;
  static const int secondaryButton = kSecondaryButton;
  static const int tertiaryButton = kTertiaryButton; // Middle button
  final int button;
  final void Function(DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final void Function()? onPanCancel;
  final Widget? child;
  final HitTestBehavior behavior;

  const MousePanGesture({
    super.key,
    this.button = 0,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior = HitTestBehavior.translucent,
    this.child,
  });

  @override
  State<MousePanGesture> createState() => _MousePanGestureState();
}

class _MousePanGestureState extends State<MousePanGesture> {
  final FocusNode _focusNode = FocusNode();
  bool _cancel = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          _cancel = true;
          widget.onPanCancel?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: RawGestureDetector(
        behavior: widget.behavior,
        gestures: {
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(
              debugOwner: this,
              allowedButtonsFilter: (buttons) => buttons & widget.button != 0,
            ),
            (instance) {
              instance
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = (details) {
                  _focusNode.requestFocus();
                  _cancel = false;
                  widget.onPanStart?.call(details);
                }
                ..onUpdate = (details) {
                  if (_cancel) {
                    return;
                  }
                  widget.onPanUpdate?.call(details);
                }
                ..onEnd = (details) {
                  if (_cancel) {
                    return;
                  }
                  widget.onPanEnd?.call(details);
                }
                ..onCancel = () {
                  _cancel = true;
                  widget.onPanCancel?.call();
                };
            },
          )
        },
        child: widget.child,
      ),
    );
  }
}

class Box extends StatelessWidget {
  final Size size;
  final Widget? child;

  const Box({
    super.key,
    required this.size,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    double flipX = size.width < 0 ? -1 : 1;
    double flipY = size.height < 0 ? -1 : 1;
    return Transform.scale(
      scaleX: flipX,
      scaleY: flipY,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: size.width.abs(),
        height: size.height.abs(),
        child: child,
      ),
    );
  }
}

class IsolationPainter extends CustomPainter {
  static const double _big = 999999999999999;
  static const Offset _bigOffset = Offset(-_big / 2, -_big / 2);
  static const Size _bigSize = Size(_big, _big);
  static Iterable<Path> createBounds(Iterable<CanvasItem> items) {
    return items.map((e) => e.globalBoundingBox.path);
  }

  final Iterable<Path> holes;
  final Color color;

  const IsolationPainter({
    required this.holes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Rect bounds = _bigOffset & _bigSize;
    Path path = Path()..addRect(bounds);
    path.fillType = PathFillType.evenOdd;
    Path clipPath = Path();
    for (final hole in holes) {
      clipPath = Path.combine(PathOperation.union, clipPath, hole);
    }
    path.addPath(clipPath, Offset.zero);
    canvas.clipPath(path);
    canvas.drawRect(bounds, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant IsolationPainter oldDelegate) {
    return !iterableEquals(oldDelegate.holes, holes) ||
        oldDelegate.color != color;
  }
}

class SnappingPreviewPainter extends CustomPainter {
  static const Offset _startOffset = Offset(-99999, 0);
  static const Offset _endOffset = Offset(99999, 0);
  final List<SnappingResult> points;
  final Color color;
  final double strokeWidth;

  const SnappingPreviewPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final point in points) {
      final Paint paint = Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final mainAxisTarget = point.mainAxisTarget;
      final crossAxisTarget = point.crossAxisTarget;

      var mainAxisPosition = mainAxisTarget.position;
      var mainAxisAngle = mainAxisTarget.rotation;
      var angleAddition =
          mainAxisTarget.direction == Axis.horizontal ? kDeg90 : 0;
      mainAxisAngle += angleAddition;
      Offset mainAxisStartLine =
          mainAxisPosition + rotatePoint(_startOffset, mainAxisAngle);
      Offset mainAxisEndLine =
          mainAxisPosition + rotatePoint(_endOffset, mainAxisAngle);
      canvas.drawLine(mainAxisStartLine, mainAxisEndLine, paint);

      if (crossAxisTarget != null) {
        var crossAxisPosition = crossAxisTarget.position;
        Offset crossAxisStartLine = crossAxisPosition +
            rotatePoint(_startOffset, mainAxisAngle + kDeg90);
        Offset crossAxisEndLine =
            crossAxisPosition + rotatePoint(_endOffset, mainAxisAngle + kDeg90);
        canvas.drawLine(crossAxisStartLine, crossAxisEndLine, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SnappingPreviewPainter oldDelegate) {
    return !iterableEquals(oldDelegate.points, points) ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Matrix4 globalTransform;
  final bool shouldScaleX;
  final bool shouldScaleY;
  final Alignment alignment;
  final Alignment selfAlignment;
  final Size itemSize;
  final Size size;
  final Color? borderColor;
  final double? strokeWidth;
  final Color? color;
  final EdgeInsets margin;

  BoundingBoxPainter({
    required this.globalTransform,
    required this.shouldScaleX,
    required this.shouldScaleY,
    required this.itemSize,
    required this.size,
    required this.alignment,
    required this.selfAlignment,
    this.margin = EdgeInsets.zero,
    this.borderColor,
    this.strokeWidth,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset topLeft = Offset.zero;
    var handleSize = this.size.toOffset();
    var transformScale = globalTransform.transformScale;
    if (!shouldScaleX && !shouldScaleY) {
      handleSize =
          handleSize.scale(1 / transformScale.dx, 1 / transformScale.dy);
    } else if (!shouldScaleX) {
      handleSize = handleSize.scale(1 / transformScale.dx, 1);
    } else if (!shouldScaleY) {
      handleSize = handleSize.scale(1, 1 / transformScale.dy);
    }
    Offset bottomRight = topLeft + handleSize;
    Offset topRight = topLeft + Offset(handleSize.dx, 0);
    Offset bottomLeft = topLeft + Offset(0, handleSize.dy);

    topLeft = topLeft - margin.topLeft.divideBy(transformScale);
    bottomRight = bottomRight + margin.bottomRight.divideBy(transformScale);
    topRight =
        topRight - Offset(margin.right, margin.top).divideBy(transformScale);
    bottomLeft = bottomLeft -
        Offset(margin.left, margin.bottom).divideBy(transformScale);

    Size itemSize = this.itemSize;
    Offset alignedItemSize = alignment.alongSize(itemSize);
    Offset alignedSize = selfAlignment.alongOffset(handleSize);

    topLeft = topLeft - alignedSize + alignedItemSize;
    bottomRight = bottomRight - alignedSize + alignedItemSize;
    topRight = topRight - alignedSize + alignedItemSize;
    bottomLeft = bottomLeft - alignedSize + alignedItemSize;
    topLeft = globalTransform.transformPoint(topLeft);
    bottomRight = globalTransform.transformPoint(bottomRight);
    topRight = globalTransform.transformPoint(topRight);
    bottomLeft = globalTransform.transformPoint(bottomLeft);
    Path path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    if (borderColor != null && strokeWidth != null) {
      Paint paint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth!;
      canvas.drawPath(path, paint);
    }
    if (color != null) {
      Paint paint = Paint()..color = color!;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.globalTransform != globalTransform ||
        oldDelegate.size != size ||
        oldDelegate.alignment != alignment ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.margin != margin;
  }

  @override
  bool? hitTest(Offset position) {
    Offset topLeft = Offset.zero;
    var handleSize = this.size.toOffset();
    var transformScale = globalTransform.transformScale;
    if (!shouldScaleX && !shouldScaleY) {
      handleSize =
          handleSize.scale(1 / transformScale.dx, 1 / transformScale.dy);
    } else if (!shouldScaleX) {
      handleSize = handleSize.scale(1 / transformScale.dx, 1);
    } else if (!shouldScaleY) {
      handleSize = handleSize.scale(1, 1 / transformScale.dy);
    }
    Offset bottomRight = topLeft + handleSize;
    Offset topRight = topLeft + Offset(handleSize.dx, 0);
    Offset bottomLeft = topLeft + Offset(0, handleSize.dy);

    topLeft = topLeft - margin.topLeft.divideBy(transformScale);
    bottomRight = bottomRight + margin.bottomRight.divideBy(transformScale);
    topRight =
        topRight - Offset(margin.right, margin.top).divideBy(transformScale);
    bottomLeft = bottomLeft -
        Offset(margin.left, margin.bottom).divideBy(transformScale);

    Size itemSize = this.itemSize;
    Offset alignedItemSize = alignment.alongSize(itemSize);
    Offset alignedSize = selfAlignment.alongOffset(handleSize);

    topLeft = topLeft - alignedSize + alignedItemSize;
    bottomRight = bottomRight - alignedSize + alignedItemSize;
    topRight = topRight - alignedSize + alignedItemSize;
    bottomLeft = bottomLeft - alignedSize + alignedItemSize;
    topLeft = globalTransform.transformPoint(topLeft);
    bottomRight = globalTransform.transformPoint(bottomRight);
    topRight = globalTransform.transformPoint(topRight);
    bottomLeft = globalTransform.transformPoint(bottomLeft);
    Path path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    return path.contains(position);
  }
}
