import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class CanvasItemWidget extends StatefulWidget {
  final CanvasItemState state;

  const CanvasItemWidget({
    super.key,
    required this.state,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

int count = 0;

class _CanvasItemWidgetState extends State<CanvasItemWidget>
    with AutomaticKeepAliveClientMixin {
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
    setState(() {
      widget.state.forceRelayout();
    });
  }

  @override
  bool get wantKeepAlive =>
      widget.state.parent != null || widget.state is RootCanvasItemState;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    assert(
        widget.state.hasSize, 'CanvasItem ${widget.state} not been laid out');
    var innerSize = widget.state.item.layoutData
        .computeInnerSize(widget.state, widget.state.size);
    Matrix4 transform = widget.state.item.layoutData
        .computeMatrix(widget.state, widget.state.size);
    Offset position = widget.state.parentData.position;
    Offset? editorOffset = widget.state.item.editorOffset;
    if (editorOffset != null) {
      transform.translate(editorOffset.dx, editorOffset.dy);
    }
    return GroupData(
      position: position,
      child: IgnorePointer(
        ignoring: editorOffset != null,
        child: GroupWidget(
          size: widget.state.size,
          children: [
            Transform(
              transform: transform,
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
                    '${widget.state.item.debugLabel}(${widget.state.size.width}, ${widget.state.size.height}) (rot: ${((widget.state.item.layoutData.rotation ?? 0) * 180 / pi).toStringAsFixed(2)})'),
              ),
            ),
            Transform(
              transform: widget.state.item.layoutData
                  .computeBoundingBoxMatrix(widget.state.size),
              child: SizedBox(
                width: innerSize.width,
                height: innerSize.height,
                child: MetaData(
                  behavior: HitTestBehavior.translucent,
                  metaData: BoundingBoxData(widget.state),
                ),
              ),
            ),
            if (widget.state is CanvasObjectState)
              ListenableBuilder(
                listenable: Listenable.merge(
                    (widget.state as CanvasObjectState).children),
                builder: (context, child) {
                  return Transform(
                    transform: transform,
                    child: GroupWidget(
                        size: innerSize,
                        debugLabel: '${widget.state.item} children',
                        children: [
                          ...(widget.state as CanvasObjectState)
                              .children
                              .sorted(_sortChildren)
                              .map((child) {
                            return CanvasItemWidget(
                              key: ValueKey(child),
                              state: child,
                            );
                          }),
                        ]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  int _sortChildren(CanvasItemState a, CanvasItemState b) {
    // if it has editorOffset, it should be on top
    if (a.item.editorOffset != null && b.item.editorOffset == null) {
      return 1;
    }
    if (a.item.editorOffset == null && b.item.editorOffset != null) {
      return -1;
    }
    return 0;
  }
}

class GroupWidget extends MultiChildRenderObjectWidget {
  final Size size;
  final String? debugLabel;
  const GroupWidget({
    super.key,
    required this.size,
    required super.children,
    this.debugLabel,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GroupRenderObject(size);
  }

  @override
  void updateRenderObject(
      BuildContext context, GroupRenderObject renderObject) {
    renderObject.debugLabel = debugLabel;
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

class GroupParentData extends ContainerBoxParentData<RenderBox> {
  Alignment? alignment;
}

class AlignedGroupData extends ParentDataWidget<GroupParentData> {
  final Alignment alignment;
  const AlignedGroupData({
    super.key,
    required this.alignment,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final GroupParentData parentData =
        renderObject.parentData as GroupParentData;
    bool needsLayout = false;
    if (parentData.alignment != alignment) {
      parentData.alignment = alignment;
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

class GroupRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  Size groupSize;

  String? debugLabel;

  GroupRenderObject(Size size, [this.debugLabel]) : groupSize = size;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GroupRenderObject($debugLabel)';
  }

  @override
  void performLayout() {
    var child = firstChild;
    var size = constraints.constrain(groupSize);
    while (child != null) {
      var childParentData = child.parentData as GroupParentData;
      child.layout(const BoxConstraints());
      if (childParentData.alignment != null) {
        childParentData.offset = childParentData.alignment!.alongSize(
          size,
        );
      }
      child = childParentData.nextSibling;
    }
    this.size = size;
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
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    } else {
      return false;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
