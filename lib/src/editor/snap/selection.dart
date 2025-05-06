import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/selection/selection.dart';
import 'package:canvas/src/editor/snap/absolute.dart';
import 'package:canvas/src/editor/snap/item.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:canvas/src/layout/flex.dart';
import 'package:flutter/widgets.dart';

class SelectionSnapAnchor extends AbsoluteSnapAnchor {
  final SelectionGroup group;

  const SelectionSnapAnchor({
    required this.group,
    required super.point,
  });

  @override
  SnapAnchor shift(Offset offset) {
    return SelectionSnapAnchor(
      group: group,
      point: point + offset,
    );
  }

  @override
  bool canSnapInto(SnapAnchor other) {
    if (other is CanvasItemSnapAnchor) {
      var otherItem = other.item;
      var groupParent = group.parent;
      var layout = groupParent.item.layout;
      if (layout is FlexLayout) {
        if (groupParent.children.contains(otherItem)) {
          return false;
        }
      }
    }
    return super.canSnapInto(other);
  }

  @override
  String toString() {
    return 'SelectionSnapAnchor{group: $group, point: $point}';
  }
}
