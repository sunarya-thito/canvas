import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WidgetKey {
  final CanvasItem item;

  const WidgetKey(this.item);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WidgetKey && other.item == item;
  }

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() {
    return 'WidgetKey{item: $item}';
  }
}

class GizmoKey {
  final CanvasItem item;

  const GizmoKey(this.item);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GizmoKey && other.item == item;
  }

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() {
    return 'GizmoKey{item: $item}';
  }
}

class BoundingBoxKey {
  final CanvasItem item;

  const BoundingBoxKey(this.item);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BoundingBoxKey && other.item == item;
  }

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() {
    return 'BoundingBoxKey{item: $item}';
  }
}

abstract class CanvasItem {
  final GlobalKey widgetKey = GlobalKey();
  final GlobalKey gizmoKey = GlobalKey();
  final GlobalKey boundingBoxKey = GlobalKey();
  final List<CanvasItemState> _attachedStates = [];
  CanvasLayoutData get layoutData;
  set layoutData(CanvasLayoutData value);

  String? get debugLabel;

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

  // Editor specific properties
  Offset? get editorOffset;
  set editorOffset(Offset? value);
  //
}

class CanvasObject extends CanvasItem {
  CanvasLayout _layout;
  CanvasLayoutData _layoutData;
  List<CanvasItem> _children = [];
  Offset? _editorOffset;
  @override
  List<CanvasObjectState> get _attachedStates =>
      super._attachedStates.cast<CanvasObjectState>();

  final String? debugLabel;

  CanvasObject({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
    this.debugLabel,
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

  Offset? get editorOffset => _editorOffset;
  set editorOffset(Offset? value) {
    if (value != _editorOffset) {
      _editorOffset = value;
      for (var state in _attachedStates) {
        state.markNeedsLayout();
      }
    }
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
        state.requestRelayout();
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
        state.requestRelayout();
      }
    }
  }

  List<CanvasItem> get children => List.unmodifiable(_children);

  set children(List<CanvasItem> value) {
    if (!listEquals(value, _children)) {
      _children = value;
      for (var state in _attachedStates) {
        state.buildChildren(value);
        state.requestRelayout();
      }
    }
  }

  @override
  String toString() {
    return 'CanvasObject{debugLabel: $debugLabel}';
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
  GlobalKey get widgetKey => item.widgetKey;
  GlobalKey get gizmoKey => item.gizmoKey;
  GlobalKey get boundingBoxKey => item.boundingBoxKey;
  CanvasItemState? get parent;
  CanvasItem get item;
  CanvasParentData? _parentData;
  _CachedLayout? _layoutResult;
  CanvasParentData get parentData {
    var parentData = _parentData;
    assert(parentData != null, 'Parent data not set');
    return parentData!;
  }

  bool isDescendantOf(CanvasItemState state) {
    var parent = this.parent;
    while (parent != null) {
      if (parent == state) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  Size get size {
    assert(_layoutResult != null, 'CanvasItem $this has not been laid out');
    return _layoutResult!.size;
  }

  bool hasLayoutPerformedFor(
      BoxConstraints constraints, TextDirection textDirection) {
    return _layoutResult != null &&
        _layoutResult!.constraints == constraints &&
        _layoutResult!.textDirection == textDirection;
  }

  bool get hasSize => _layoutResult != null;

  void requestRelayout();
  void requestChildRelayout(CanvasItemState child);

  void markNeedsLayout();

  void forceRelayout() {
    var cached = _layoutResult;
    assert(cached != null, 'CanvasItem $this has not been laid out');
    forceLayout(cached!.constraints, cached.textDirection);
  }

  final List<CanvasItemState> _children = [];
  List<CanvasItemState> get children => List.unmodifiable(_children);

  void dispose() {}

  void layout(BoxConstraints constraints, TextDirection textDirection) {
    if (!hasLayoutPerformedFor(constraints, textDirection)) {
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

  set children(List<CanvasItemState> children) {
    item.children = children.map((e) => e.item).toList();
  }

  @override
  void requestRelayout() {
    var parent = this.parent;
    if (parent == null) {
      markNeedsLayout();
    } else {
      parent.markNeedsLayout();
      markNeedsLayout();
    }
  }

  @override
  void requestChildRelayout(CanvasItemState child) {
    item.layout.visitRelayout(this, child);
  }

  @override
  void markNeedsLayout() {
    notifyListeners();
  }

  @override
  void dispose() {
    buildChildren(const []);
    super.dispose();
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

  @override
  String toString() {
    return 'CanvasObjectState{item: $item}';
  }
}

class CanvasRoot extends CanvasObject {
  CanvasRoot({
    CanvasLayout layout = const FixedLayout(),
    CanvasLayoutData layoutData = const AbsoluteLayoutData(),
    List<CanvasItem> children = const [],
    String? debugLabel,
  }) : super(
          layout: layout,
          layoutData: layoutData,
          children: children,
          debugLabel: debugLabel,
        );

  @override
  CanvasItemState createState({CanvasItemState? parent}) {
    return RootCanvasItemState(
      parent: parent,
      item: this,
    );
  }
}

class RootCanvasItemState extends CanvasObjectState {
  RootCanvasItemState({
    CanvasItemState? parent,
    required CanvasRoot item,
  }) : super(
          parent: parent,
          item: item,
        );
}
