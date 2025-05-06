import 'package:canvas/src/item.dart';
import 'package:canvas/src/item/parent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CanvasPath extends BaseCanvasParent {
  List<Offset> _points;

  CanvasPath(
      {super.layoutData,
      required List<Offset> points,
      super.layout,
      super.children,
      super.debugLabel,
      super.locked,
      super.layoutGrids,
      super.overflow})
      : _points = points;

  List<Offset> get points => _points;

  set points(List<Offset> value) {
    if (!listEquals(value, _points)) {
      _points = value;
      notifyStates();
    }
  }
}

class CanvasPathState extends BaseCanvasParentState {
  CanvasPathState({
    required CanvasPath super.item,
    required super.parent,
  });

  @override
  CanvasPath get item => super.item as CanvasPath;

  @override
  Path getPath() {
    final Path path = Path();
    if (item.points.isNotEmpty) {
      path.moveTo(item.points[0].dx, item.points[0].dy);
      for (int i = 1; i < item.points.length; i++) {
        path.lineTo(item.points[i].dx, item.points[i].dy);
      }
    }
    return path;
  }
}
