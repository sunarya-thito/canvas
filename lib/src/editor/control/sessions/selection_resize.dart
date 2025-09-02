import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class SelectionResizeControlSession extends EditorControlSession {
  final Selection selection;
  final Alignment anchor;

  SelectionResizeControlSession(this.selection, this.anchor);

  @override
  void visitSnapAnchor(SnapAnchorVisitor visitor) {}

  @override
  void onDragStart() {
    for (var item in selection.items) {
      item.sessionOldLayoutData = item.item.layoutData;
    }
  }

  @override
  void onDragUpdate() {
    for (var group in selection.groups) {
      if (group.items.length == 1) {
        var item = group.items.first;
        _resizeSingleObject(
          delta,
          anchor,
          item,
          (item, positionDelta, sizeDelta) {
            print('Resize single object: $positionDelta, $sizeDelta');
            item.item.layoutData = item.sessionOldLayoutData!
                .drag(item, Delta.fromOffset(positionDelta))
                .resize(item, sizeDelta);
          },
        );
      }
    }
  }
}

typedef _ResizeCallback = void Function(
    CanvasItemState item, Offset positionDelta, Size sizeDelta);

void _resizeSingleObject(Delta delta, Alignment anchor, CanvasItemState item,
    _ResizeCallback callback) {
  var transform = item.item.layoutData.computeTransform(Size.zero);
  var parentTransform = item.computeParentTransform();
  var alignment = _convertAlignmentToOffset(anchor);
  var transformedDelta = delta.transform(parentTransform);
  var positionDelta = Offset(
    transformedDelta.deltaX * (1 - alignment.dx),
    transformedDelta.deltaY * (1 - alignment.dy),
  );
  var sizeDelta = Size(0, 0);
  callback(item, positionDelta, sizeDelta);
}

Offset _convertAlignmentToOffset(Alignment alignment) {
  // alignment is in the range of -1 to 1, where 0 is the center
  // convert to the range of 0 to 1 where 0.5 is the center
  return Offset(
    (alignment.x + 1) / 2,
    (alignment.y + 1) / 2,
  );
}

Offset _adjustDelta(Offset delta, Alignment anchor) {
  if (anchor.y == 0) {
    delta = Offset(delta.dx, 0);
  }
  if (anchor.x == 0) {
    delta = Offset(0, delta.dy);
  }
  return delta;
}

void _resizeMultipleObjects(
    Delta delta,
    Alignment anchor,
    List<CanvasItemState> items,
    TransformControlBox box,
    _ResizeCallback callback) {}
