import 'dart:math';

import 'package:canvas/src/common.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class CanvasItemWidget extends StatefulWidget {
  final CanvasItemState state;

  const CanvasItemWidget({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

int count = 0;

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  int _count = 0;
  @override
  void initState() {
    _count = count++;
    super.initState();
    widget.state.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant CanvasItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_update);
      widget.state.addListener(_update);
    }
  }

  Color _computeRandomColor(int hash) {
    Random random = Random(hash);
    return Color.fromARGB(
      255,
      random.nextInt(255),
      random.nextInt(255),
      random.nextInt(255),
    );
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
    var innerSize =
        widget.state.item.layoutData.computeInnerSize(widget.state.size);
    return GroupData(
      position: widget.state.parentData.position,
      child: GroupWidget(
        size: widget.state.size,
        children: [
          SizedBox.fromSize(
            size: widget.state.size,
            child: Transform(
              transform:
                  widget.state.item.layoutData.computeMatrix(widget.state.size),
              child: Center(
                child: Container(
                  width: innerSize.width,
                  height: innerSize.height,
                  decoration: BoxDecoration(
                    color: _computeRandomColor(_count),
                    border: Border.all(
                      color: _computeRandomColor(_count + 1),
                      width: 3,
                    ),
                  ),
                  child: Text(
                      '(${widget.state.size.width}, ${widget.state.size.height}) (rot: ${(widget.state.item.layoutData.rotation ?? 0) * 180 / pi})'),
                ),
              ),
            ),
          ),
          SizedBox.fromSize(
            size: widget.state.size,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromARGB(255, 0, 0, 0),
                  width: 1,
                ),
              ),
            ),
          ),
          ...widget.state.children.map((child) {
            return CanvasItemWidget(
              state: child,
            );
          }),
        ],
      ),
    );
  }
}

class GroupWidget extends MultiChildRenderObjectWidget {
  final Size size;
  const GroupWidget({
    super.key,
    required this.size,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GroupRenderObject(size);
  }

  @override
  void updateRenderObject(
      BuildContext context, GroupRenderObject renderObject) {
    if (renderObject.groupSize != size) {
      renderObject.groupSize = size;
      renderObject.markNeedsLayout();
    }
  }
}

class GroupData extends ParentDataWidget<GroupParentData> {
  final Offset position;
  const GroupData({
    super.key,
    required this.position,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final GroupParentData parentData =
        renderObject.parentData as GroupParentData;
    bool needsLayout = false;
    if (parentData.offset != position) {
      parentData.offset = position;
      needsLayout = true;
    }
    if (needsLayout) {
      var targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GroupWidget;
}

class GroupParentData extends ContainerBoxParentData<RenderBox> {}

class GroupRenderObject extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, GroupParentData> {
  Size groupSize;

  GroupRenderObject(Size size) : groupSize = size;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  void performLayout() {
    var child = firstChild;
    while (child != null) {
      var childParentData = child.parentData as GroupParentData;
      child.layout(const BoxConstraints(), parentUsesSize: true);
      child = childParentData.nextSibling;
    }
    size = groupSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      var childParentData = child.parentData as GroupParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      var childParentData = child.parentData as GroupParentData;
      var hitTestResult = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (hitTestResult) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}
