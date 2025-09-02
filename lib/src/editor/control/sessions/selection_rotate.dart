import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class SelectionRotateControlSession extends EditorControlSession {
  final Selection selection;
  final SelectionGroup group;

  SelectionRotateControlSession({
    required this.selection,
    required this.group,
  });

  @override
  void visitSnapAnchor(SnapAnchorVisitor visitor) {}

  @override
  void onDragStart() {
    for (var group in selection.groups) {
      var parentTransform = group.parent.computeGlobalTransform();
      var origin = _computeOrigin(group);
      for (var item in group.items) {
        item.sessionOrigin = origin;
        var transform = parentTransform * item.computeTransform();
        Offset center = transformOffset(
            item.item.layoutData.computeOrigin(item.size), transform);
        item.sessionCenter = center;
        item.sessionOldLayoutData = item.item.layoutData;
      }
    }
  }

  Offset _computeOrigin(SelectionGroup group) {
    return group.computeEditorBoundingBox().center;
  }

  @override
  void onDragUpdate() {
    for (var i = 0; i < selection.groups.length; i++) {
      var group = selection.groups[i];
      for (var item in group.items) {
        var origin = item.sessionOrigin!;
        var deltaAngle = _computeDeltaAngle(origin);
        if (editor.snappingConfiguration.rotatedSnap) {
          deltaAngle = editor.snappingConfiguration.snapRotation(deltaAngle);
        }
        var newLayoutData = item.sessionOldLayoutData!.rotateBy(deltaAngle);
        Offset topLeft = item.sessionCenter!;
        Offset before = rotatePoint(topLeft, 0, origin);
        Offset after = rotatePoint(topLeft, deltaAngle, origin);
        Offset delta = after - before;
        item.item.layoutData =
            newLayoutData.drag(item, Delta.fromOffset(delta));
      }
    }
  }

  @override
  void onDragCancel() {
    for (var group in selection.groups) {
      var parent = group.parent;
      if (parent is CanvasFrameState && parent.item.layout is FlexLayout) {
        for (var item in group.items) {
          item.item.layoutData = item.sessionOldLayoutData!;
        }
        continue;
      }
    }
  }

  double _computeDeltaAngle(Offset origin) {
    Offset start = delta.start;
    Offset end = delta.end;
    double startAngle = (start - origin).direction;
    double endAngle = (end - origin).direction;
    return endAngle - startAngle;
  }
}
