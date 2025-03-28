import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class SelectionClient {
  static const SelectionClient local = SelectionClient._();
  final BoxDecoration? decoration;

  const SelectionClient({
    required BoxDecoration this.decoration,
  });

  const SelectionClient._() : decoration = null;
}

class SelectionBox {
  final SelectionClient client;
  final ValueNotifier<Offset> start;
  final ValueNotifier<Offset> end;

  const SelectionBox({
    required this.client,
    required this.start,
    required this.end,
  });

  SelectionBox.local({
    Offset start = Offset.zero,
  })  : client = SelectionClient.local,
        start = ValueNotifier(start),
        end = ValueNotifier(start);

  void update({required Offset end}) {
    this.end.value = end;
  }

  Rect get rect {
    return Rect.fromPoints(start.value, end.value);
  }
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

  TransformControlBox getTransformControlBox({Matrix4? parentTransform}) {
    if (selectedItems.length == 1) {
      CanvasItemState? current = selectedItems.first;
      var transform = current.item.layoutData.computeTranslatedMatrix(
        current,
        current.size,
      );
      var shear = current.item.layoutData.shear ?? Offset.zero;
      while (current != null) {
        var parent = current.parent;
        if (parent is CanvasItemState) {
          transform = parent.item.layoutData.computeTranslatedMatrix(
                parent,
                parent.size,
              ) *
              transform;
          shear += parent.item.layoutData.shear ?? Offset.zero;
        }
        current = parent;
      }
      var first = selectedItems.first;
      return TransformControlBox(
        size: first.item.layoutData.computeInnerSize(first, first.size),
        transform:
            parentTransform == null ? transform : parentTransform * transform,
        shear: shear,
      );
    }
    List<Offset> points = [];
    for (var item in selectedItems) {
      var layoutData = item.item.layoutData;
      var size = layoutData.computeInnerSize(item, item.size);
      CanvasItemState? current = item;
      var transform = item.item.layoutData.computeTranslatedMatrix(
        current,
        current.size,
      );
      while (current != null) {
        var parent = current.parent;
        if (parent is CanvasItemState) {
          transform = parent.item.layoutData.computeTranslatedMatrix(
                parent,
                parent.size,
              ) *
              transform;
        }
        current = parent;
      }
      Polygon polygon = Polygon.fromRect(Offset.zero & size);
      polygon = polygon.transform(transform);
      points.addAll(polygon.points);
    }
    Polygon polygon = Polygon(points);
    Matrix4 transform =
        parentTransform == null ? Matrix4.identity() : parentTransform.clone();
    Rect boundingBox = polygon.boundingBox;
    transform.translate(boundingBox.topLeft.dx, boundingBox.topLeft.dy);
    return TransformControlBox(
      size: boundingBox.size,
      transform: transform,
      shear: Offset.zero,
    );
  }

  @override
  String toString() {
    return 'SelectionGroup{parent: $parent, selectedItems: $selectedItems}';
  }
}

class TransformControlBox {
  final Size size;
  final Matrix4 transform;
  final Offset shear;

  const TransformControlBox({
    required this.size,
    required this.transform,
    required this.shear,
  });
}

class Selection {
  // when selection is created, it is created with a list of groups
  // from the selected items based on the parent item.
  final ValueNotifier<List<SelectionGroup>> groups;
  final SelectionClient client;

  Selection({
    required List<SelectionGroup> groups,
    required this.client,
  }) : groups = ValueNotifier(groups);

  factory Selection.fromSelection(List<CanvasItemState> selectedItems,
      {SelectionClient client = SelectionClient.local}) {
    List<SelectionGroup> groups = [];

    int? findPossibleGroup(CanvasItemState item) {
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].parent == item.parent) {
          return i;
        }
      }
      return null;
    }

    for (var item in selectedItems) {
      var parent = item.parent;
      if (selectedItems.contains(parent)) {
        // when parent is selected, its children should not be selected
        // because they are already selected by the parent.
        continue;
      }
      int? possibleGroup = findPossibleGroup(item);
      if (possibleGroup != null) {
        var group = groups[possibleGroup];
        groups[possibleGroup] = SelectionGroup(
          parent: group.parent,
          selectedItems: [...group.selectedItems, item],
        );
      } else {
        groups.add(SelectionGroup(
          parent: item.parent!,
          selectedItems: [item],
        ));
      }
    }
    return Selection(
      groups: groups,
      client: client,
    );
  }

  int? _findPossibleGroup(CanvasItemState item) {
    for (var i = 0; i < groups.value.length; i++) {
      if (groups.value[i].parent == item.parent) {
        return i;
      }
    }
    return null;
  }

  void addSelection(CanvasItemState item) {
    int? possibleGroup = _findPossibleGroup(item);
    if (possibleGroup != null) {
      var group = List.of(groups.value);
      group[possibleGroup] = SelectionGroup(
        parent: group[possibleGroup].parent,
        selectedItems: [...group[possibleGroup].selectedItems, item],
      );
      groups.value = group;
    } else {
      var group = List.of(groups.value);
      group.add(SelectionGroup(
        parent: item.parent!,
        selectedItems: [item],
      ));
      groups.value = group;
    }
  }

  @override
  String toString() {
    return 'Selection{groups: $groups, client: $client}';
  }
}
