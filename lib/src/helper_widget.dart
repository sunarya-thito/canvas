import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GroupWidget extends MultiChildRenderObjectWidget {
  GroupWidget({
    Key? key,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGroup();
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGroup renderObject) {
    renderObject.markNeedsLayout();
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
  RenderGroup({
    List<RenderBox>? children,
  }) {
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
    size = constraints.biggest;
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
      context.paintChild(child, offset + childParentData.offset);
      child = childParentData.nextSibling;
    }
  }
}

class PanGesture extends StatefulWidget {
  final void Function(DragStartDetails details) onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final void Function(DragEndDetails details) onPanEnd;
  final void Function() onPanCancel;
  final Widget child;

  const PanGesture({
    Key? key,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.child,
  }) : super(key: key);

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
          widget.onPanCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          _focusNode.requestFocus();
          _cancel = false;
          widget.onPanStart(details);
        },
        onPanUpdate: (details) {
          if (_cancel) {
            return;
          }
          widget.onPanUpdate(details);
        },
        onPanEnd: (details) {
          if (_cancel) {
            return;
          }
          widget.onPanEnd(details);
        },
        onPanCancel: () {
          _cancel = true;
          widget.onPanCancel();
        },
        child: widget.child,
      ),
    );
  }
}

class Box extends StatelessWidget {
  final Size size;
  final Widget child;

  const Box({
    Key? key,
    required this.size,
    required this.child,
  }) : super(key: key);

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
