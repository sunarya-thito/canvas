import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/control.dart';
import 'package:canvas/src/editor/extra.dart';
import 'package:flutter/widgets.dart';

class SmartSelectionRow {
  final SmartSelection selection;
  final List<CanvasItemState> columns;

  SmartSelectionRow({
    required this.selection,
    required this.columns,
  }) {
    analyze();
  }

  void analyze() {}

  late double _spacing;

  double get spacing => _spacing;
  set spacing(double value) {
    _spacing = value;
    // TODO: update the spacing of the columns on the object
  }
}

class SmartSelection {
  final List<SmartSelectionRow> rows;

  SmartSelection({
    required this.rows,
  }) {
    analyze();
  }

  void analyze() {}
}

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

  Iterable<ExtraTransformationControl> buildControls({
    required Selection selection,
    required CanvasEditorHandler editor,
    required SelectionGroup selectionGroup,
    required Matrix4 parentTransform,
  }) sync* {
    if (selectedItems.length == 1) {
      var first = selectedItems.first;
      var transform = first.item.layoutData.computeTranslatedMatrix(first);
      // yield* first.buildControls(
      //     editor: editor,
      //     parentTransform: parentTransform,
      //     transform: transform);
      return;
    }
    // TODO: when items are arranged nicely, it should has a SMART CONTROL like in figma
    // where it can adjust gaps, rearrange items, etc. Prioritize Columns then Rows!
    // when the smart control dot is enabled, user can adjust size of the object singularly
  }

  TransformControlBox getTransformControlBox({Matrix4? parentTransform}) {
    if (selectedItems.length == 1) {
      CanvasItemState? current = selectedItems.first;
      var transform = current.item.layoutData.computeTranslatedMatrix(
        current,
      );
      while (current != null) {
        var parent = current.parent;
        if (parent is CanvasItemState) {
          transform = parent.item.layoutData.computeTranslatedMatrix(
                parent,
              ) *
              transform;
        }
        current = parent;
      }
      var first = selectedItems.first;
      return TransformControlBox(
        size: first.innerSize,
        transform:
            parentTransform == null ? transform : parentTransform * transform,
      );
    }
    List<Offset> points = [];
    for (var item in selectedItems) {
      var size = item.innerSize;
      CanvasItemState? current = item;
      var transform = item.item.layoutData.computeTranslatedMatrix(
        current,
      );
      while (current != null) {
        var parent = current.parent;
        if (parent is CanvasItemState) {
          transform = parent.item.layoutData.computeTranslatedMatrix(
                parent,
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

  const TransformControlBox({
    required this.size,
    required this.transform,
  });

  Rect get boundingBox {
    Offset topLeft = transformOffset(Offset.zero, transform);
    Offset topRight = transformOffset(
      Offset(size.width, 0),
      transform,
    );
    Offset bottomLeft = transformOffset(
      Offset(0, size.height),
      transform,
    );
    Offset bottomRight = transformOffset(
      Offset(size.width, size.height),
      transform,
    );
    return Rect.fromPoints(
      Offset(
        min(topLeft.dx, bottomLeft.dx),
        min(topLeft.dy, topRight.dy),
      ),
      Offset(
        max(topRight.dx, bottomRight.dx),
        max(bottomLeft.dy, bottomRight.dy),
      ),
    );
  }
}

class Selection {
  // when selection is created, it is created with a list of groups
  // from the selected items based on the parent item.
  final List<SelectionGroup> groups;
  final SelectionClient client;
  final ValueNotifier<EditorControlDelta> editorOffset =
      ValueNotifier(EditorControlDelta.zero);

  Selection({
    required this.groups,
    required this.client,
  });

  List<CanvasItemState> get selectedItems {
    return groups.expand((group) => group.selectedItems).toList();
  }

  CanvasItemState? get singleSelection {
    if (groups.length == 1) {
      var firstGroup = groups.first;
      if (firstGroup.selectedItems.length == 1) {
        return firstGroup.selectedItems.first;
      }
    }
    return null;
  }

  bool get isSingleSelection {
    return groups.length == 1 && groups.first.selectedItems.length == 1;
  }

  List<EditorProperty> get editableProperties {
    Map<Key, List<EditorProperty>> grouped = {};
    for (var group in groups) {
      for (var item in group.selectedItems) {
        if (item is EditableCanvasItemState) {
          List<EditorProperty> properties =
              (item as EditableCanvasItemState).properties;
          for (var property in properties) {
            List<EditorProperty>? group = grouped[property.key];
            if (group == null) {
              grouped[property.key] = [property];
            } else {
              group.add(property);
            }
          }
        }
      }
    }
    // return grouped.values.map(
    //   (value) {
    //     return EditorProperty.combined(value);
    //   },
    // ).toList();
    // use EditorProperty#combineWith instead
    List<EditorProperty> properties = [];
    for (var entry in grouped.entries) {
      var value = entry.value;
      if (value.isNotEmpty) {
        EditorProperty? combined;
        for (var property in value) {
          if (combined == null) {
            combined = property;
          } else {
            combined = combined.combineWith(property);
          }
        }
        if (combined != null) {
          properties.add(combined);
        }
      }
    }
    return properties;
  }

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
          selectedItems: [
            ...group.selectedItems.where(
              (selectedItem) => selectedItem != item,
            ),
            item,
          ],
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

  Rect computeBoundingBox({Matrix4? parentTransform}) {
    Rect? boundingBox;
    for (var group in groups) {
      var box = group.getTransformControlBox(parentTransform: parentTransform);
      if (boundingBox == null) {
        boundingBox = box.boundingBox;
      } else {
        boundingBox = boundingBox.expandToInclude(box.boundingBox);
      }
    }
    boundingBox ??= Rect.zero;
    boundingBox = boundingBox.shift(editorOffset.value
        .transform(parentTransform ?? Matrix4.identity())
        .delta);
    return boundingBox;
  }

  Iterable<ExtraTransformationControl> buildControls({
    required CanvasEditorHandler editor,
    required SelectionGroup selectionGroup,
    required Matrix4 parentTransform,
  }) {
    if (groups.length == 1) {
      var first = groups.first;
      // return first.buildControls(
      //   selection: this,
      //   editor: editor,
      //   parentTransform: parentTransform,
      // );
    }
    return const [];
  }

  int? _findPossibleGroup(CanvasItemState item) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].parent == item.parent) {
        return i;
      }
    }
    return null;
  }

  Selection addSelection(CanvasItemState item) {
    return Selection.fromSelection(
      [...groups.expand((group) => group.selectedItems), item],
      client: client,
    );
    // int? possibleGroup = _findPossibleGroup(item);
    // List<SelectionGroup> newGroups;
    // if (possibleGroup != null) {
    //   newGroups = List.of(groups);
    //   newGroups[possibleGroup] = SelectionGroup(
    //     parent: newGroups[possibleGroup].parent,
    //     selectedItems: [
    //       ...newGroups[possibleGroup].selectedItems.where(
    //             (selectedItem) => selectedItem != item,
    //           ),
    //       item,
    //     ],
    //   );
    // } else {
    //   newGroups = List.of(groups);
    //   newGroups.add(SelectionGroup(
    //     parent: item.parent!,
    //     selectedItems: [item],
    //   ));
    // }
    // return Selection(
    //   groups: newGroups,
    //   client: client,
    // );
  }

  @override
  String toString() {
    return 'Selection{groups: $groups, client: $client}';
  }

  bool contains(CanvasItemState item) {
    for (var group in groups) {
      if (group.selectedItems.contains(item)) {
        return true;
      }
    }
    return false;
  }

  bool containsOrDescendant(CanvasItemState other) {
    for (var group in groups) {
      for (var item in group.selectedItems) {
        if (item == other || other.isDescendantOf(item)) {
          return true;
        }
      }
    }
    return false;
  }

  Selection removeSelection(CanvasItemState item) {
    int? possibleGroup = _findPossibleGroup(item);
    List<SelectionGroup> newGroups;
    if (possibleGroup != null) {
      newGroups = List.of(groups);
      newGroups[possibleGroup] = SelectionGroup(
        parent: newGroups[possibleGroup].parent,
        selectedItems: [
          ...newGroups[possibleGroup].selectedItems.where(
                (selectedItem) => selectedItem != item,
              ),
        ],
      );
    } else {
      newGroups = List.of(groups);
      newGroups.removeWhere((group) => group.selectedItems.contains(item));
    }
    return Selection(
      groups: newGroups,
      client: client,
    );
  }

  bool get isEmpty {
    return groups.isEmpty ||
        groups.every((group) => group.selectedItems.isEmpty);
  }
}
