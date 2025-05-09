import 'package:canvas/canvas.dart';
import 'package:canvas/src/item/frame.dart';
import 'package:flutter/widgets.dart';

class SelectionMoveControlSession extends EditorControlSession {
  final Selection selection;

  SelectionMoveControlSession({
    required this.selection,
  });

  @override
  void visitSnapAnchor(SnapAnchorVisitor visitor) {
    var parent = _parentEnd;
    if (parent is CanvasFrameState && parent.item.layout is FlexLayout) {
      return;
    }
    var offset = delta.delta;
    for (var group in selection.groups) {
      var box = group.getTransformControlBox();
      var transform = box.transform;
      var size = box.size;
      var topLeft = transformOffset(Offset.zero, transform) + offset;
      var topRight = transformOffset(Offset(size.width, 0), transform) + offset;
      var bottomLeft =
          transformOffset(Offset(0, size.height), transform) + offset;
      var bottomRight =
          transformOffset(Offset(size.width, size.height), transform) + offset;
      var center =
          transformOffset(Offset(size.width / 2, size.height / 2), transform) +
              offset;
      if (!visitor(SelectionSnapAnchor(group: group, point: topLeft))) {
        return;
      }
      if (!visitor(SelectionSnapAnchor(group: group, point: topRight))) {
        return;
      }
      if (!visitor(SelectionSnapAnchor(group: group, point: bottomLeft))) {
        return;
      }
      if (!visitor(SelectionSnapAnchor(group: group, point: bottomRight))) {
        return;
      }
      if (!visitor(SelectionSnapAnchor(group: group, point: center))) {
        return;
      }
    }
  }

  CanvasParentState? _parentStart;
  CanvasParentState? _parentEnd;
  bool _lockReparenting = false;
  bool _isReparenting = false;

  @override
  void onDragStart() {
    if (editor.allowReparenting) {
      _startReparenting();
    }
  }

  @override
  void onEditorUpdate() {
    if (editor.allowReparenting) {
      _startReparenting();
    } else {
      _stopReparenting();
    }
  }

  void _startReparenting() {
    if (_isReparenting) {
      return;
    }
    for (var group in selection.groups) {
      for (var item in group.items) {
        item.dragOffset = Offset.zero;
        item.targetReparent = null;
        item.targetReorderIndex = null;
        item.clearReorderOffsets();
        var parent = item.parent;
        if (parent != null) {
          for (var sibling in parent.children) {
            sibling.clearReorderOffsets();
            sibling.targetReorderIndex = null;
          }
        }
      }
    }
    _isReparenting = true;
    _lockReparenting = false;
    CanvasItemState? targetHit = editor.findItemAt(delta.end);
    while (targetHit != null) {
      if (targetHit is CanvasParentState &&
          !selection.containsOrDescendant(targetHit)) {
        _parentStart = targetHit;
        break;
      }
      targetHit = targetHit.parent;
    }
  }

  void _stopReparenting() {
    if (!_isReparenting) {
      return;
    }
    _isReparenting = false;
    _parentEnd?.targetDrop = null;
    _parentEnd = null;
    _parentStart = null;
    _lockReparenting = false;
    for (var group in selection.groups) {
      for (var item in group.items) {
        item.targetReparent = null;
        item.targetReorderIndex = null;
        item.clearReorderOffsets();
        var parent = item.parent;
        if (parent != null) {
          for (var sibling in parent.children) {
            sibling.clearReorderOffsets();
            sibling.targetReorderIndex = null;
          }
        }
      }
    }
  }

  @override
  void onDragUpdate() {
    selection.editorDragOffset.value = delta;
    CanvasParentState? targetReparent;
    if (editor.allowReparenting) {
      CanvasItemState? targetHit = editor.findItemAt(
        delta.end,
        filter: (parent) {
          return parent is CanvasParentState &&
              selection.items.any((child) => parent.acceptReparent(child));
        },
      );
      for (var group in selection.groups) {
        for (var item in group.items) {
          var layoutData = item.item.layoutData;
          if (layoutData is FlexibleLayoutData &&
              targetHit != null &&
              targetHit is CanvasParentState &&
              targetHit.item.layoutData is FlexibleLayoutData) {
            targetHit = null;
            break;
          }
        }
      }
      if (targetHit is CanvasParentState &&
          (targetHit != _parentStart || _lockReparenting)) {
        targetReparent = targetHit;
      }
      _parentEnd?.targetDrop = null;
      _parentEnd = targetReparent;
      _parentEnd?.targetDrop = selection;
      if (_parentStart != targetHit &&
          targetHit is CanvasParentState &&
          !_lockReparenting) {
        _lockReparenting = true;
      }
    }
    for (var group in selection.groups) {
      for (var item in group.items) {
        var transform = Matrix4.inverted(item.computeGlobalTransform());
        var transformedDelta = delta.transform(transform);
        item.dragOffset = transformedDelta.delta;
        if (targetReparent != null && targetReparent.acceptReparent(item)) {
          item.targetReparent = targetReparent;
        } else {
          item.targetReparent = null;
        }
        if (item.targetReparent == null || item.targetReparent == item.parent) {
          var parent = item.parent;
          if (parent is CanvasFrameState) {
            var parentLayout = parent.item.layout;
            parentLayout.handleDrag(parent, item, delta);
          }
        } else {
          var parent = item.parent;
          if (parent is CanvasParentState) {
            for (var sibling in parent.children) {
              if (sibling != item) {
                sibling.clearReorderOffsets();
                sibling.targetReorderIndex = null;
              }
            }
          }
        }
      }
    }
  }

  @override
  void onDragEnd() {
    for (var group in selection.groups) {
      for (var item in group.items) {
        var reorderTarget = item.targetReorderIndex;
        if (reorderTarget != null) {
          var parent = item.parent;
          parent?.reorderItem(item, reorderTarget);
          continue;
        }
        var reparentTarget = item.targetReparent;
        if (reparentTarget != null && reparentTarget != item.parent) {
          var oldParent = item.parent;
          var commonParent = item.findCommonParent(reparentTarget);
          if (commonParent != null) {
            var reparentedTransform = commonParent.computeGlobalTransform() *
                item.computeEditorGlobalTransformUntil(commonParent);
            var reparentedLayoutData = item.item.layoutData
                .transferTo(item, reparentTarget, reparentedTransform);
            item.item.layoutData = reparentedLayoutData;
            oldParent?.item.removeChild(item.item);
            reparentTarget.item.addChild(item.item);
          }
          continue;
        }
        var layoutData = item.item.layoutData;
        Matrix4 parentTransform =
            item.parent?.computeGlobalTransform() ?? Matrix4.identity();
        var offsetDelta = delta.transform(parentTransform);
        item.item.layoutData = layoutData.drag(item, offsetDelta);
      }
    }
    _resetEditorOffset();
  }

  @override
  void onDragCancel() {
    _resetEditorOffset();
  }

  void _resetEditorOffset() {
    selection.editorDragOffset.value = null;
    for (var group in selection.groups) {
      for (var item in group.items) {
        item.dragOffset = null;
        item.targetReparent = null;
        item.targetReorderIndex = null;
        item.clearReorderOffsets();
        var parent = item.parent;
        if (parent != null) {
          for (var sibling in parent.children) {
            sibling.clearReorderOffsets();
            sibling.targetReorderIndex = null;
          }
        }
      }
      _stopReparenting();
    }
  }
}
