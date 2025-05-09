import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control/box.dart';
import 'package:flutter/widgets.dart';

import 'client.dart';

class SelectionGroup {
  final CanvasParentState parent;
  final List<CanvasItemState> items;

  const SelectionGroup({
    required this.parent,
    required this.items,
  });

  TransformControlBox getTransformControlBox({Matrix4? parentTransform}) {
    print('items: $items');
    if (items.length == 1) {
      CanvasItemState item = items.first;
      var transform = item.computeTransform(parentTransform: parentTransform);
      return TransformControlBox(
        size: item.size,
        transform: transform,
      );
    }
    // List<Offset> points = items
    //     .map((item) {
    //       var offset = item.parentData.position;
    //       var size = item.size;
    //       return [
    //         offset,
    //         offset + Offset(size.width, 0),
    //         offset + Offset(size.width, size.height),
    //         offset + Offset(0, size.height),
    //       ];
    //     })
    //     .expand((e) => e)
    //     .toList();
    // var transform = parent.computeTransform(parentTransform: parentTransform);
    // var transformedPoints = points.map((point) {
    //   return transformOffset(point, transform);
    // }).toList();
    // var minX = transformedPoints
    //     .map((point) => point.dx)
    //     .reduce((a, b) => a < b ? a : b);
    // var minY = transformedPoints
    //     .map((point) => point.dy)
    //     .reduce((a, b) => a < b ? a : b);
    // var maxX = transformedPoints
    //     .map((point) => point.dx)
    //     .reduce((a, b) => a > b ? a : b);
    // var maxY = transformedPoints
    //     .map((point) => point.dy)
    //     .reduce((a, b) => a > b ? a : b);
    parentTransform =
        parent.computeGlobalTransform(parentTransform: parentTransform);
    Iterable<Offset> points = items.map(
      (item) {
        var transform = item.computeTransform(parentTransform: parentTransform);
        Iterable<Offset> itemPoints = [
          Offset(0, 0),
          Offset(item.size.width, 0),
          Offset(item.size.width, item.size.height),
          Offset(0, item.size.height),
        ];
        itemPoints = itemPoints.map((point) {
          return transformOffset(point, transform);
        });
        return itemPoints;
      },
    ).expand((e) => e);

    var minX = points.map((point) => point.dx).reduce((a, b) => a < b ? a : b);
    var minY = points.map((point) => point.dy).reduce((a, b) => a < b ? a : b);
    var maxX = points.map((point) => point.dx).reduce((a, b) => a > b ? a : b);
    var maxY = points.map((point) => point.dy).reduce((a, b) => a > b ? a : b);
    var width = maxX - minX;
    var height = maxY - minY;
    var size = Size(width, height);
    parentTransform.translate(minX, minY);
    return TransformControlBox(
      size: size,
      transform: parentTransform,
    );
  }

  Rect computeBoundingBox({Matrix4? parentTransform}) {
    if (items.length == 1) {
      return items.first.computeGlobalBounds(parentTransform);
    }
    List<Offset> points = items
        .map((item) {
          var offset = item.parentData.position;
          var size = item.size;
          return [
            offset,
            offset + Offset(size.width, 0),
            offset + Offset(size.width, size.height),
            offset + Offset(0, size.height),
          ];
        })
        .expand((e) => e)
        .toList();
    var transform =
        parent.computeGlobalTransform(parentTransform: parentTransform);
    var transformedPoints = points.map((point) {
      return transformOffset(point, transform);
    }).toList();
    var minX = transformedPoints
        .map((point) => point.dx)
        .reduce((a, b) => a < b ? a : b);
    var minY = transformedPoints
        .map((point) => point.dy)
        .reduce((a, b) => a < b ? a : b);
    var maxX = transformedPoints
        .map((point) => point.dx)
        .reduce((a, b) => a > b ? a : b);
    var maxY = transformedPoints
        .map((point) => point.dy)
        .reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class Selection {
  final List<SelectionGroup> groups;
  final SelectionClient client;
  final ValueNotifier<Delta> editorDragOffset =
      ValueNotifier<Delta>(Delta.zero);

  Selection({
    required this.groups,
    required this.client,
  });

  List<CanvasItemState> get items {
    return groups.expand((group) => group.items).toList();
  }

  CanvasItemState? get singleSelection {
    if (groups.length == 1) {
      var group = groups.first;
      if (group.items.length == 1) {
        return group.items.first;
      }
    }
    return null;
  }

  bool get isSingleSelection {
    return groups.length == 1 && groups.first.items.length == 1;
  }

  bool get isEmpty {
    return groups.isEmpty || groups.every((group) => group.items.isEmpty);
  }

  factory Selection.fromSelection(List<CanvasItemState> items,
      {SelectionClient client = SelectionClient.local}) {
    List<SelectionGroup> groups = [];

    int? findPossibleGroup(CanvasItemState item) {
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].parent == item.parent) {
          return i;
        }
      }
      return null;
    }

    for (CanvasItemState item in items) {
      if (item.parent == null) {
        continue;
      }
      int? groupIndex = findPossibleGroup(item);
      if (groupIndex != null) {
        groups[groupIndex].items.add(item);
      } else {
        groups.add(SelectionGroup(
          parent: item.parent!,
          items: [item],
        ));
      }
    }
    return Selection(
      groups: groups,
      client: client,
    );
  }

  Selection addSelection(CanvasItemState item) {
    return Selection.fromSelection(
      items + [item],
      client: client,
    );
  }

  Selection removeSelection(CanvasItemState item) {
    return Selection.fromSelection(
      items.where((i) => i != item).toList(),
      client: client,
    );
  }

  bool contains(CanvasItemState item) {
    return groups.any((group) => group.items.contains(item));
  }

  bool containsOrDescendant(CanvasItemState other) {
    return groups.any((group) {
      for (var item in group.items) {
        if (item == other) {
          return true;
        }
        if (item is CanvasParentState) {
          if (other.isDescendantOf(item)) {
            return true;
          }
        }
      }
      return false;
    });
  }

  Rect computeBoundingBox({Matrix4? parentTransform}) {
    if (isEmpty) {
      return Rect.zero;
    }
    if (isSingleSelection) {
      return singleSelection!.computeGlobalBounds(parentTransform);
    }
    Rect? boundingBox;
    for (var group in groups) {
      Rect groupBoundingBox =
          group.computeBoundingBox(parentTransform: parentTransform);
      if (boundingBox == null) {
        boundingBox = groupBoundingBox;
      } else {
        boundingBox = boundingBox.expandToInclude(groupBoundingBox);
      }
    }
    return boundingBox ?? Rect.zero;
  }
}
