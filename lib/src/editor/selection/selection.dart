import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control/box.dart';
import 'package:canvas/src/editor/debug/debug.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'client.dart';

class SelectionGroup implements Listenable {
  final CanvasParentState parent;
  final List<CanvasItemState> items;

  const SelectionGroup({
    required this.parent,
    required this.items,
  });

  @override
  void addListener(VoidCallback listener) {
    parent.addListener(listener);
    for (var item in items) {
      item.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    parent.removeListener(listener);
    for (var item in items) {
      item.removeListener(listener);
    }
  }

  TransformControlBox getTransformControlBox({Matrix4? parentTransform}) {
    if (items.length == 1) {
      CanvasItemState item = items.first;
      var transform =
          item.computeGlobalTransform(parentTransform: parentTransform);
      return TransformControlBox(
        size: item.size,
        transform: transform,
      );
    }
    Iterable<Offset> points = items.map(
      (item) {
        var transform = item.computeTransform();
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
    var transform =
        parentTransform == null ? Matrix4.identity() : parentTransform.clone();
    transform = transform * parent.computeGlobalTransform();
    var minX = points.map((point) => point.dx).reduce((a, b) => a < b ? a : b);
    var minY = points.map((point) => point.dy).reduce((a, b) => a < b ? a : b);
    var maxX = points.map((point) => point.dx).reduce((a, b) => a > b ? a : b);
    var maxY = points.map((point) => point.dy).reduce((a, b) => a > b ? a : b);
    var width = maxX - minX;
    var height = maxY - minY;
    var size = Size(width, height);
    transform.translate(minX, minY);
    return TransformControlBox(
      size: size,
      transform: transform,
    );
  }

  Rect computeEditorBoundingBox({Matrix4? parentTransform}) {
    if (items.length == 1) {
      return items.first.computeEditorGlobalBounds(parentTransform);
    }
    Rect? boundingBox;
    for (var item in items) {
      Rect itemBoundingBox = item.computeEditorGlobalBounds(parentTransform);
      if (boundingBox == null) {
        boundingBox = itemBoundingBox;
      } else {
        boundingBox = boundingBox.expandToInclude(itemBoundingBox);
      }
    }
    if (boundingBox == null) {
      return Rect.zero;
    }
    return boundingBox;
  }
}

class Selection implements Listenable {
  final List<SelectionGroup> groups;
  final SelectionClient client;
  final ValueNotifier<Delta?> editorDragOffset = ValueNotifier(null);

  Selection({
    required this.groups,
    required this.client,
  });

  List<CanvasItemState> get items {
    return groups.expand((group) => group.items).toList();
  }

  @override
  int get hashCode => items.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Selection) {
      return false;
    }
    return listEquals(
      items,
      other.items,
    );
  }

  @override
  void addListener(VoidCallback listener) {
    for (var group in groups) {
      group.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (var group in groups) {
      group.removeListener(listener);
    }
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
          group.computeEditorBoundingBox(parentTransform: parentTransform);
      if (boundingBox == null) {
        boundingBox = groupBoundingBox;
      } else {
        boundingBox = boundingBox.expandToInclude(groupBoundingBox);
      }
    }
    return boundingBox ?? Rect.zero;
  }

  Rect computeEditorBoundingBox({Matrix4? parentTransform}) {
    if (isEmpty) {
      return Rect.zero;
    }
    if (isSingleSelection) {
      return singleSelection!.computeEditorGlobalBounds(parentTransform);
    }
    Rect? boundingBox;
    for (var group in groups) {
      Rect groupBoundingBox =
          group.computeEditorBoundingBox(parentTransform: parentTransform);
      if (boundingBox == null) {
        boundingBox = groupBoundingBox;
      } else {
        boundingBox = boundingBox.expandToInclude(groupBoundingBox);
      }
    }
    return boundingBox ?? Rect.zero;
  }
}
