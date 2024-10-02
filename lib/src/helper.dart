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
  void onInstantSelection(Offset position) {
    _start(position, true);
  }

  CanvasSelectionSession _start(Offset position, bool instant) {
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
    Layout layout = createdItem.layout;
    controller.visitTo(
      targetParent,
      (item) {
        layout = layout.transferToChild(item.layout);
      },
    );
    createdItem.layout = layout;
    targetParent.addChild(createdItem);
    return CreateObjectSession(
      targetParent: targetParent,
      createdItem: createdItem,
    );
  }

  @override
  CanvasSelectionSession onSelectionStart(CanvasSelectSession session) {
    return _start(session.startPosition, false);
  }
}

class CreateObjectSession extends CanvasSelectionSession {
  final CanvasItem targetParent;
  final CanvasItem createdItem;

  CreateObjectSession({
    required this.targetParent,
    required this.createdItem,
  });

  @override
  void onSelectionCancel() {
    targetParent.removeChild(createdItem);
  }

  @override
  void onSelectionChange(CanvasSelectSession session, Offset delta) {
    Layout layout = createdItem.layout;
    layout = layout.resizeBottomRight(delta);
    createdItem.layout = layout;
  }

  @override
  void onSelectionEnd(CanvasSelectSession session) {}
}
