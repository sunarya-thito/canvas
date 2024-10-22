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
    CanvasItem? targetParent;
    if (createAtRoot) {
      targetParent = controller.root;
    } else {
      CanvasHitTestResult result = CanvasHitTestResult();
      controller.hitTest(result, position);
      if (result.path.isEmpty) {
        targetParent = controller.root;
      } else {
        targetParent = result.path.last.item;
      }
    }
    CanvasItem createdItem = createItem(position, instant);
    createdItem.selected = true;
    ItemConstraints layout = createdItem.constraints;
    controller.visitTo(
      targetParent,
      (item) {
        layout = layout.transferToChild(item.constraints);
      },
    );
    createdItem.constraints = layout;
    targetParent.addChild(createdItem);
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
  final CanvasItem targetParent;
  final CanvasItem createdItem;
  final ItemConstraints initialLayout;

  CreateObjectSession({
    required this.handle,
    required this.targetParent,
    required this.createdItem,
  }) : initialLayout = createdItem.constraints;

  @override
  void onSelectionCancel() {
    targetParent.removeChild(createdItem);
  }

  @override
  void onSelectionChange(CanvasSelectSession session, Offset totalDelta) {
    LayoutSnapping snapping = handle.createLayoutSnapping(
      (details) {
        return details != createdItem;
      },
    );
    ItemConstraints newLayout = initialLayout.resizeBottomRight(
        createdItem, totalDelta,
        snapping: snapping,
        symmetric: handle.symmetricResize,
        proportional: handle.proportionalResize);
    createdItem.constraints = newLayout;
  }

  @override
  void onSelectionEnd(CanvasSelectSession session) {}
}
