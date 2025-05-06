import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

abstract class EditorDragGesture {
  const EditorDragGesture();
  EditorDragGestureSession createState({required CanvasEditor editor});
  MouseCursor get cursor => MouseCursor.defer;
  bool get allowEditorInteraction => true;
  bool get allowSnapping => false;
}

abstract class EditorDragGestureSession {
  final CanvasEditor editor;

  EditorDragGestureSession({
    required this.editor,
  });

  Ticker? _ticker;
  Offset? _shift;

  void startTicker() {
    if (_ticker != null) {
      return;
    }
    _lastTick = null;
    _ticker = editor.createTicker(onTick);
    _ticker!.start();
  }

  void stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void _handleCursorPosition(Offset position) {
    position = editor.localToGlobal(position);
    Size viewportSize = editor.viewportSize;
    double shiftX = 0;
    double shiftY = 0;

    EdgeInsets shiftPadding = EdgeInsets.all(20);

    double verticalMin = shiftPadding.top;
    double verticalMax = viewportSize.height - shiftPadding.bottom;
    double horizontalMin = shiftPadding.left;
    double horizontalMax = viewportSize.width - shiftPadding.right;

    if (position.dy < verticalMin) {
      shiftY = -(verticalMin - position.dy) / shiftPadding.top;
    } else if (position.dy > verticalMax) {
      shiftY = (position.dy - verticalMax) / shiftPadding.bottom;
    }

    if (position.dx < horizontalMin) {
      shiftX = -(horizontalMin - position.dx) / shiftPadding.left;
    } else if (position.dx > horizontalMax) {
      shiftX = (position.dx - horizontalMax) / shiftPadding.right;
    }
    if (shiftX != 0 || shiftY != 0) {
      _shift = Offset(-shiftX, -shiftY);
      startTicker();
    } else {
      stopTicker();
    }
  }

  Duration? _lastTick;
  void onTick(Duration elapsed) {
    Duration delta = elapsed - (_lastTick ?? Duration.zero);
    if (_shift != null) {
      var shift = Offset(
        _shift!.dx * delta.inMilliseconds / 2,
        _shift!.dy * delta.inMilliseconds / 2,
      );

      onShift(shift);
    }
    _lastTick = elapsed;
  }

  MouseCursor get cursor => MouseCursor.defer;

  void onShift(Offset shift) {
    editor.dragViewport(shift);
  }

  void onDragStart(Offset start) {
    _handleCursorPosition(start);
  }

  void onDrag(Offset start, Offset end) {
    _handleCursorPosition(end);
  }

  void onDragRelease(Offset start, Offset end) {}
  void onDragCancel() {}

  void dispose() {
    editor.stopMouseGesture(this);
    stopTicker();
  }
}

class EditorSelectDragGesture extends EditorDragGesture {
  const EditorSelectDragGesture();
  @override
  EditorDragGestureSession createState({required CanvasEditor editor}) {
    return EditorSelectDragGestureHandler(
      editor: editor,
    );
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;
}

class EditorSelectDragGestureHandler extends EditorDragGestureSession {
  EditorSelectDragGestureHandler({
    required super.editor,
  });

  late SelectionBox _selectionRect;
  Selection? _oldSelection;

  late Offset _end;

  @override
  void onDragStart(Offset start) {
    super.onDragStart(start);
    _end = start;
    _oldSelection = editor.localSelection;
    _selectionRect = SelectionBox.local(start: start);
    editor.addSelectionRect(_selectionRect);
  }

  @override
  void onShift(Offset shift) {
    super.onShift(shift);
    _selectionRect.end.value = _end + shift;
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDrag(Offset start, Offset end) {
    _end = end;
    super.onDrag(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDragRelease(Offset start, Offset end) {
    super.onDragRelease(start, end);
    _selectionRect.start.value = start;
    _selectionRect.end.value = end;
    editor.removeSelectionRect(_selectionRect);
    editor.selectFromRect(_selectionRect, _oldSelection);
  }

  @override
  void onDragCancel() {
    super.onDragCancel();
    editor.removeSelectionRect(_selectionRect);
    editor.localSelection = _oldSelection;
  }
}

class EditorMoveDragGesture extends EditorDragGesture {
  const EditorMoveDragGesture();
  @override
  EditorDragGestureSession createState({required CanvasEditor editor}) {
    return EditorMoveDragGestureHandler(
      editor: editor,
    );
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  bool get allowEditorInteraction => false;
}

class EditorMoveDragGestureHandler extends EditorDragGestureSession {
  EditorMoveDragGestureHandler({
    required super.editor,
  });

  @override
  void onDrag(Offset start, Offset end) {
    super.onDrag(start, end);
    start = editor.globalToLocal(start);
    end = editor.globalToLocal(end);
    editor.dragViewport(end - start);
  }

  @override
  void onShift(Offset shift) {
    editor.transform = editor.transform.copyWith(
      offset: editor.transform.offset - shift,
    );
  }

  @override
  MouseCursor get cursor {
    return SystemMouseCursors.grabbing;
  }
}

class EditorCreateObjectDragGesture extends EditorDragGesture {
  final CanvasItem Function(CanvasEditor editor) createItem;
  const EditorCreateObjectDragGesture({
    required this.createItem,
  });

  @override
  bool get allowSnapping => true;

  @override
  EditorDragGestureSession createState({required CanvasEditor editor}) {
    return EditorCreateObjectDragGestureHandler(
      editor: editor,
      createItem: createItem,
    );
  }

  @override
  bool get allowEditorInteraction => false;
}

class EditorCreateObjectDragGestureHandler extends EditorDragGestureSession {
  final CanvasItem Function(CanvasEditor editor) createItem;
  EditorCreateObjectDragGestureHandler({
    required super.editor,
    required this.createItem,
  });

  late CanvasObjectState _parent;
  late CanvasItem _item;
  late CanvasLayoutData _layoutData;

  @override
  void onDragStart(Offset start) {
    super.onDragStart(start);
    _item = createItem(editor);
    _item.allowSnapping = false;
    CanvasHitTestResult result = CanvasHitTestResult();
    editor.hitTest(result, start);
    CanvasObjectState? hitParent;
    for (var entry in result.path) {
      if (entry.target is CanvasObjectState) {
        var item = entry.target as CanvasObjectState;
        hitParent = item;
        break;
      }
    }
    hitParent ??= editor.rootState;
    _parent = hitParent;
    var parentLayout = _parent.item.layout;
    CanvasItemState? insertBeforeItem;
    Matrix4 globalParentTransform = _parent.globalTransform;
    var startOffset =
        transformOffset(start, Matrix4.inverted(globalParentTransform));
    if (parentLayout is FlexLayout) {
      _layoutData = FixedLayoutData();
      _item.layoutData = _layoutData;
      // find the item before which to insert the new item
      var child = _parent.firstChild;
      var direction = parentLayout.direction;
      while (child != null) {
        if (child.item.layoutData is FixedLayoutData ||
            child.item.layoutData is FlexLayoutData) {
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
            if (previousSibling.item.layoutData is FixedLayoutData ||
                previousSibling.item.layoutData is FlexLayoutData) {
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
            if (nextSibling.item.layoutData is FixedLayoutData ||
                nextSibling.item.layoutData is FlexLayoutData) {
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
              insertBeforeItem = nextSibling;
              break;
            }
          } else {
            if (dragOffset > childCenter && dragOffset < nextCenter) {
              insertBeforeItem = nextSibling;
              break;
            }
          }
        }
        child = child.parentData.nextSibling;
      }
    } else {
      _layoutData = AbsoluteLayoutData(
        top: startOffset.dy,
        left: startOffset.dx,
      );
      _item.layoutData = _layoutData;
    }
    if (insertBeforeItem != null) {
      _parent.item.insertBefore(_item, insertBeforeItem.item);
    } else {
      _parent.item.addChild(_item);
    }
  }

  @override
  void onDrag(Offset start, Offset end) {
    super.onDrag(start, end);
    Matrix4 globalParentTransform = _parent.globalTransform;
    var startOffset =
        transformOffset(start, Matrix4.inverted(globalParentTransform));
    var endOffset =
        transformOffset(end, Matrix4.inverted(globalParentTransform));
    var newStartOffset = Offset(
        min(startOffset.dx, endOffset.dx), min(startOffset.dy, endOffset.dy));
    var newEndOffset = Offset(
        max(startOffset.dx, endOffset.dx), max(startOffset.dy, endOffset.dy));
    var delta = newEndOffset - newStartOffset;
    var currentLayoutData = _layoutData;
    if (currentLayoutData is FixedLayoutData) {
      currentLayoutData = currentLayoutData.copyWith(
        width: SizeConstraint.fixed(delta.dx),
        height: SizeConstraint.fixed(delta.dy),
      );
    } else if (currentLayoutData is AbsoluteLayoutData) {
      currentLayoutData = currentLayoutData.copyWith(
        top: newStartOffset.dy,
        left: newStartOffset.dx,
        width: delta.dx,
        height: delta.dy,
      );
    }
    _layoutData = currentLayoutData;
    _item.layoutData = _layoutData;
  }

  @override
  void onDragRelease(Offset start, Offset end) {
    super.onDragRelease(start, end);
    _item.allowSnapping = true;
  }

  @override
  void onDragCancel() {
    super.onDragCancel();
    _parent.item.removeChild(_item);
  }
}
