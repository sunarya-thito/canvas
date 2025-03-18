import 'package:canvas/src/layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

abstract class CanvasItem {
  final List<CanvasItemState> _attachedStates = [];
  CanvasLayoutData get layoutData;
  set layoutData(CanvasLayoutData value);

  void attach(CanvasItemState state) {
    _attachedStates.add(state);
  }

  void detach(CanvasItemState state) {
    _attachedStates.remove(state);
  }

  CanvasItemState createState({
    CanvasItemState? parent,
  });

  List<CanvasItemState> get activeStates => List.unmodifiable(_attachedStates);
}

class CanvasObject extends CanvasItem {
  CanvasLayout _layout;
  CanvasLayoutData _layoutData;
  List<CanvasItem> _children = [];
  @override
  List<CanvasObjectState> get _attachedStates =>
      super._attachedStates.cast<CanvasObjectState>();
  CanvasObject({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
  })  : _layout = layout,
        _layoutData = layoutData,
        _children = children;
  @override
  CanvasItemState createState({CanvasItemState? parent}) {
    return CanvasObjectState(
      parent: parent,
      item: this,
    );
  }

  @override
  void attach(CanvasItemState state) {
    super.attach(state);
    (state as CanvasObjectState).buildChildren(_children);
    state._parentData = layout.setupParentData(state, state._parentData);
  }

  CanvasLayout get layout => _layout;
  set layout(CanvasLayout value) {
    if (value != _layout) {
      _layout = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
        state._parentData = layout.setupParentData(state, state._parentData);
      }
    }
  }

  @override
  CanvasLayoutData get layoutData => _layoutData;
  @override
  set layoutData(CanvasLayoutData value) {
    if (value != _layoutData) {
      _layoutData = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
  }

  List<CanvasItem> get children => List.unmodifiable(_children);

  set children(List<CanvasItem> value) {
    for (var state in _attachedStates) {
      state.buildChildren(value);
    }
    _children = value;
  }
}

class _CachedLayout {
  final Size size;
  final BoxConstraints constraints;
  final TextDirection textDirection;

  _CachedLayout({
    required this.size,
    required this.constraints,
    required this.textDirection,
  });
}

abstract class CanvasItemState implements Listenable {
  CanvasItemState? get parent;
  CanvasItem get item;
  CanvasParentData? _parentData;
  _CachedLayout? _layoutResult;
  CanvasParentData get parentData {
    var parentData = _parentData;
    assert(parentData != null, 'Parent data not set');
    return parentData!;
  }

  Size get size {
    assert(_layoutResult != null, 'Layout not performed');
    return _layoutResult!.size;
  }

  bool hasLayoutPerformedFor(
      BoxConstraints constraints, TextDirection textDirection) {
    return _layoutResult != null &&
        _layoutResult!.constraints == constraints &&
        _layoutResult!.textDirection == textDirection;
  }

  void markNeedsLayout();

  final List<CanvasItemState> _children = [];
  List<CanvasItemState> get children => List.unmodifiable(_children);

  void dispose() {}

  void layout(BoxConstraints constraints, TextDirection textDirection) {
    if (_layoutResult == null ||
        _layoutResult!.constraints != constraints ||
        _layoutResult!.textDirection != textDirection) {
      var size = forceLayout(constraints, textDirection);
      _layoutResult = _CachedLayout(
        size: size,
        constraints: constraints,
        textDirection: textDirection,
      );
    }
  }

  Size forceLayout(BoxConstraints constraints, TextDirection textDirection);

  double computeMinIntrinsicWidth(double height);
  double computeMaxIntrinsicWidth(double height);
  double computeMinIntrinsicHeight(double width);
  double computeMaxIntrinsicHeight(double width);
}

class CanvasObjectState extends CanvasItemState with ChangeNotifier {
  @override
  final CanvasItemState? parent;
  @override
  final CanvasObject item;

  CanvasObjectState({
    this.parent,
    required this.item,
  });

  @override
  void markNeedsLayout() {
    notifyListeners();
  }

  void buildChildren(List<CanvasItem> newChildren) {
    Map<CanvasItem, CanvasItemState> oldChildren = {};
    for (var child in _children) {
      oldChildren[child.item] = child;
    }
    _children.clear();
    for (var child in newChildren) {
      CanvasItemState? oldState = oldChildren.remove(child);
      if (oldState != null) {
        _children.add(oldState);
      } else {
        CanvasItemState newState = child.createState(parent: this);
        _children.add(newState);
        child.attach(newState);
      }
    }
    for (var state in oldChildren.entries) {
      state.key.detach(state.value);
      state.value.dispose();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return item.layout.computeMinIntrinsicWidth(this, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return item.layout.computeMaxIntrinsicWidth(this, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return item.layout.computeMinIntrinsicHeight(this, width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return item.layout.computeMaxIntrinsicHeight(this, width);
  }

  @override
  Size forceLayout(BoxConstraints constraints, TextDirection textDirection) {
    return item.layout.performLayout(this, constraints, textDirection);
  }
}
