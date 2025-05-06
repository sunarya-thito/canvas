import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

typedef CanvasRulerCrossLineVisitor = double? Function();

class CanvasSnapGuideline with ChangeNotifier {
  double _offset;
  CanvasParentState? _parent;
  final Axis axis;

  CanvasSnapGuideline({
    required double offset,
    required this.axis,
    CanvasParentState? parent,
  })  : _offset = offset,
        _parent = parent;

  double get offset => _offset;

  set offset(double value) {
    if (value != _offset) {
      _offset = value;
      notifyListeners();
    }
  }

  CanvasParentState? get parent => _parent;

  set parent(CanvasParentState? parent) {
    if (parent != _parent) {
      _parent = parent;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'CanvasRulerSnapAnchor(offset: $offset, axis: $axis)';
  }
}
