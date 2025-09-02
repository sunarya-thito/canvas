import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

typedef CanvasItemProvider = CanvasItem Function(CanvasEditor editor);

class EditorCreateObjectDragGesture extends EditorGesture {
  final CanvasItemProvider itemFactory;
  const EditorCreateObjectDragGesture(this.itemFactory);

  @override
  bool get allowSnapping => true;

  @override
  bool get interceptPointerEvents => true;

  @override
  EditorGestureSession createSession(CanvasEditor editor) {
    return EditorCreateObjectDragGestureSession(
      editor,
      itemFactory,
    );
  }
}

class EditorCreateObjectDragGestureSession extends EditorGestureSession {
  final CanvasItemProvider itemFactory;

  EditorCreateObjectDragGestureSession(
    super.editor,
    this.itemFactory,
  );

  late CanvasFrameState _parent;
  late CanvasItem _item;
  late CanvasLayoutData _layoutData;

  @override
  void onDragStart() {
    _item = itemFactory(editor);
    _item.allowSnapping = false;
    CanvasHitTestResult result = CanvasHitTestResult();
    editor.hitTest(result, delta.start);
    CanvasFrameState? hitParent;
    for (var entry in result.path) {
      if (entry.target is CanvasFrameState) {
        var item = entry.target as CanvasFrameState;
        hitParent = item;
        break;
      }
    }
    var rootState = editor.rootState;
    if (rootState is CanvasFrameState) {
      hitParent ??= rootState;
    }
    if (hitParent == null) {
      return;
    }
    _parent = hitParent;
    var parentLayout = _parent.item.layout;
    CanvasItemState? insertBeforeItem;
    Matrix4 globalParentTransform = _parent.computeGlobalTransform();
    var startOffset =
        transformOffset(delta.start, Matrix4.inverted(globalParentTransform));
    if (parentLayout is FlexLayout) {
      _layoutData = FlexibleLayoutData();
      _item.layoutData = _layoutData;
      var child = _parent.firstChild;
      var direction = parentLayout.direction;
      while (child != null) {
        if (child.item.layoutData is FlexibleLayoutData) {
          var childOffset = direction == Axis.horizontal
              ? child.parentData.position.dx
              : child.parentData.position.dy;
          var childSize = direction == Axis.horizontal
              ? child.size.width
              : child.size.height;
          var childCenter = childOffset + childSize / 2;
          double? previousCenter;
          CanvasItemState? previousSibling = child.parentData.previousSibling;
          while (previousSibling != null) {
            if (previousSibling.item.layoutData is FlexibleLayoutData) {
              var previousOffset = direction == Axis.horizontal
                  ? previousSibling.parentData.position.dx
                  : previousSibling.parentData.position.dy;
              var previousSize = direction == Axis.horizontal
                  ? previousSibling.size.width
                  : previousSibling.size.height;
              previousCenter = previousOffset + previousSize / 2;
              break;
            }
            previousSibling = previousSibling.parentData.previousSibling;
          }
          double? nextCenter;
          CanvasItemState? nextSibling = child.parentData.nextSibling;
          while (nextSibling != null) {
            if (nextSibling.item.layoutData is FlexibleLayoutData) {
              var nextOffset = direction == Axis.horizontal
                  ? nextSibling.parentData.position.dx
                  : nextSibling.parentData.position.dy;
              var nextSize = direction == Axis.horizontal
                  ? nextSibling.size.width
                  : nextSibling.size.height;
              nextCenter = nextOffset + nextSize / 2;
              break;
            }
            nextSibling = nextSibling.parentData.nextSibling;
          }
          var dragOffset =
              direction == Axis.horizontal ? startOffset.dx : startOffset.dy;
          if (previousCenter == null) {
            if (dragOffset < childCenter) {
              insertBeforeItem = child;
              break;
            }
          } else {
            if (dragOffset < childCenter && dragOffset > previousCenter) {
              insertBeforeItem = child;
              break;
            }
          }
          if (nextCenter == null) {
            if (dragOffset > childCenter) {
              insertBeforeItem = child;
              break;
            }
          } else {
            if (dragOffset > childCenter && dragOffset < nextCenter) {
              insertBeforeItem = child;
              break;
            }
          }
        }
        child = child.parentData.nextSibling;
      }
    } else {
      _layoutData = AbsoluteLayoutData(
          top: AbsolutePosition(startOffset.dy),
          left: AbsolutePosition(startOffset.dx),
          width: FixedSizeConstraint(0),
          height: FixedSizeConstraint(0));
      _item.layoutData = _layoutData;
    }
    if (insertBeforeItem != null) {
      _parent.item.insertBefore(_item, insertBeforeItem.item);
    } else {
      _parent.item.addChild(_item);
    }
  }

  @override
  void onDragUpdate() {
    Matrix4 globalParentTransform = _parent.computeGlobalTransform();
    var startOffset = transformOffset(
        this.delta.start, Matrix4.inverted(globalParentTransform));
    var endOffset = transformOffset(
        this.delta.end, Matrix4.inverted(globalParentTransform));
    var newStartOffset = Offset(
        min(startOffset.dx, endOffset.dx), min(startOffset.dy, endOffset.dy));
    var newEndOffset = Offset(
        max(startOffset.dx, endOffset.dx), max(startOffset.dy, endOffset.dy));
    var delta = newEndOffset - newStartOffset;
    var currentLayoutData = _layoutData;
    if (currentLayoutData is FlexibleLayoutData) {
      _item.layoutData = FlexibleLayoutData(
        width: FixedSizeConstraint(delta.dx),
        height: FixedSizeConstraint(delta.dy),
      );
    } else if (currentLayoutData is AbsoluteLayoutData) {
      _item.layoutData = AbsoluteLayoutData(
        top: AbsolutePosition(newStartOffset.dy),
        left: AbsolutePosition(newStartOffset.dx),
        width: FixedSizeConstraint(delta.dx),
        height: FixedSizeConstraint(delta.dy),
      );
    }
    _item.layoutData = currentLayoutData;
    _layoutData = currentLayoutData;
  }

  @override
  void onDragEnd() {
    _item.allowSnapping = true;
  }

  @override
  void onDragCancel() {
    _parent.item.removeChild(_item);
  }
}
