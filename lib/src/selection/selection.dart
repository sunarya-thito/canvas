import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class SelectionClient {
  final BoxDecoration? decoration;
  final ValueNotifier<Rect> selectionRect;

  const SelectionClient({
    this.decoration,
    required this.selectionRect,
  });
}

// selection group groups a list of selected items
// together, so that they can be manipulated as a group.
class SelectionGroup {
  final CanvasItemState parent;
  final List<CanvasItemState> selectedItems;

  const SelectionGroup({
    required this.parent,
    required this.selectedItems,
  });

  GizmoBox getGizmoBox() {
    if (selectedItems.length == 1) {
      CanvasItemState? current = selectedItems.first;
      var transform =
          current.item.layoutData.computeMatrix(current, current.size);
      while (current != null) {
        current = current.parent;
        if (current != null) {
          transform = current.item.layoutData
              .computeMatrix(current, current.size)
            ..multiply(transform);
        }
      }
      return GizmoBox(
        size: selectedItems.first.size,
        transform: transform,
      );
    }
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (var item in selectedItems) {
      var layoutData = item.item.layoutData;
      var matrix = layoutData.computeMatrix(item, item.size);
      var topLeft = transformOffset(Offset(0, 0), matrix);
      var topRight = transformOffset(Offset(item.size.width, 0), matrix);
      var bottomLeft = transformOffset(Offset(0, item.size.height), matrix);
      var bottomRight = transformOffset(
        Offset(item.size.width, item.size.height),
        matrix,
      );
      left = min(
          left,
          min(topLeft.dx,
              min(topRight.dx, min(bottomLeft.dx, bottomRight.dx))));
      top = min(
          top,
          min(topLeft.dy,
              min(topRight.dy, min(bottomLeft.dy, bottomRight.dy))));
      right = max(
          right,
          max(topLeft.dx,
              max(topRight.dx, max(bottomLeft.dx, bottomRight.dx))));
      bottom = max(
          bottom,
          max(topLeft.dy,
              max(topRight.dy, max(bottomLeft.dy, bottomRight.dy))));
    }
    Matrix4 transform = Matrix4.identity();
    transform.translate(left, top);
    return GizmoBox(
      size: Size(right - left, bottom - top),
      transform: transform,
    );
  }
}

class GizmoBox {
  final Size size;
  final Matrix4 transform;

  const GizmoBox({
    required this.size,
    required this.transform,
  });
}

class Selection {
  // when selection is created, it is created with a list of groups
  // from the selected items based on the parent item.
  final List<SelectionGroup> groups;
  final SelectionClient client;

  const Selection({
    required this.groups,
    required this.client,
  });

  int? _findPossibleGroup(CanvasItemState item) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].parent == item.parent) {
        return i;
      }
    }
    return null;
  }

  Selection addSelection(CanvasItemState item) {
    int? possibleGroup = _findPossibleGroup(item);
    if (possibleGroup != null) {
      var group = groups[possibleGroup];
      return Selection(
        groups: [
          ...groups.sublist(0, possibleGroup),
          SelectionGroup(
            parent: group.parent,
            selectedItems: [...group.selectedItems, item],
          ),
          ...groups.sublist(possibleGroup + 1),
        ],
        client: client,
      );
    }
    return Selection(
      groups: [
        ...groups,
        SelectionGroup(
          parent: item.parent!,
          // if parent is null, then it is RootObject
          // RootObject is not selectable so its safe here!
          selectedItems: [item],
        ),
      ],
      client: client,
    );
  }
}
