import 'package:flutter/widgets.dart';

import '../canvas.dart';

class CreateObjectHandler extends CanvasSelectionHandler {
  final CanvasController controller;
  final bool createAtRoot;
  final CanvasItem Function(Offset offset, bool instant) createItem;

  CreateObjectHandler({
    required this.controller,
    required this.createItem,
    this.createAtRoot = false,
  });

  @override
  bool get shouldCancelObjectDragging => true;

  @override
  void onInstantSelection(CanvasViewportHandle handle, Offset position) {
    _start(handle, position, true);
  }

  CanvasSelectionSession _start(
      CanvasViewportHandle handle, Offset position, bool instant) {
    CanvasItemNode? targetParent;
    if (createAtRoot) {
      targetParent = controller.root.toNode();
    } else {
      CanvasHitTestResult result = CanvasHitTestResult();
      controller.hitTest(result, position);
      if (result.path.isEmpty) {
        targetParent = controller.root.toNode();
      } else {
        targetParent = result.path.last.node;
      }
    }
    CanvasItem createdItem = createItem(position, instant);
    createdItem.selected = true;
    Layout layout = createdItem.layout;
    controller.visitTo(
      targetParent.item,
      (item) {
        layout = layout.transferToChild(item.layout);
      },
    );
    createdItem.layout = layout;
    targetParent.item.addChild(createdItem);
    return CreateObjectSession(
      handle: handle,
      targetParent: targetParent,
      createdItem: createdItem,
    );
  }

  @override
  CanvasSelectionSession onSelectionStart(
      CanvasViewportHandle handle, CanvasSelectSession session) {
    return _start(handle, session.startPosition, false);
  }
}

class CreateObjectSession extends CanvasSelectionSession {
  final CanvasViewportHandle handle;
  final CanvasItemNode targetParent;
  final CanvasItem createdItem;
  final Layout initialLayout;

  CreateObjectSession({
    required this.handle,
    required this.targetParent,
    required this.createdItem,
  }) : initialLayout = createdItem.layout;

  @override
  void onSelectionCancel() {
    targetParent.item.removeChild(createdItem);
  }

  @override
  void onSelectionChange(CanvasSelectSession session, Offset totalDelta) {
    LayoutSnapping snapping =
        handle.createLayoutSnapping(createdItem.toNode(targetParent));
    Layout newLayout = initialLayout.resizeBottomRight(totalDelta,
        snapping: snapping,
        symmetric: handle.symmetricResize,
        proportional: handle.proportionalResize);
    createdItem.layout = newLayout;
  }

  @override
  void onSelectionEnd(CanvasSelectSession session) {}
}
