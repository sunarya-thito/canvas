import 'package:canvas/canvas.dart';
import 'package:canvas/src/collections.dart';
import 'package:canvas/src/editor/grid/grid.dart';
import 'package:canvas/src/editor/selection/selection.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasItem {
  String? get debugLabel;
  CanvasOverflow get overflow;
  set overflow(CanvasOverflow value);

  CanvasLayoutData get layoutData;
  set layoutData(CanvasLayoutData value);

  bool get locked;
  set locked(bool value);

  List<CanvasItemState> get attachedStates;

  void attach(CanvasItemState state);
  void detach(CanvasItemState state);

  CanvasItemState createState({CanvasParentState? parent});

  bool allowSnapping = true;
}

abstract class CanvasItemState implements Listenable, HitTestTarget {
  CanvasParentData? get unmountableParentData;
  set unmountableParentData(CanvasParentData? value);
  CanvasParentData get parentData;
  CanvasItemEditorData get editorData;
  set editorData(CanvasItemEditorData value);
  CanvasParentState? get parent;
  CanvasItem get item;
  Matrix4 computeTransform({Matrix4? parentTransform});
  Matrix4 computeEditorTransform({Matrix4? parentTransform});
  Matrix4 computeGlobalTransform({Matrix4? parentTransform});
  Matrix4 computeEditorGlobalTransform({Matrix4? parentTransform});
  Matrix4 computeEditorGlobalTransformUntil(CanvasParentState topParent);
  CanvasParentState? findCommonParent(CanvasItemState other);
  bool visitSnapAnchor(SnapAnchorVisitor visitor, {Matrix4? parentTransform});
  Rect computeBounds([Matrix4? parentTransform]);
  Rect computeGlobalBounds([Matrix4? parentTransform]);
  bool hitTest(CanvasHitTestResult result, Offset position);
  bool hitTestSelf(CanvasHitTestResult result, Offset position);
  void selectTest(CanvasHitTestResult result, Path path);
  void selectTestSelf(CanvasHitTestResult result, Path path);
  Widget render(BuildContext context, {Matrix4? transform});
  Widget renderEditor(BuildContext context, CanvasEditor editor,
      {Matrix4? transform});
  Size get size;
  void relayout();
  void layout(Size size);
  void forceLayout(Size size);
  double computeMinIntrinsicWidth(double height);
  double computeMaxIntrinsicWidth(double height);
  double computeMinIntrinsicHeight(double width);
  double computeMaxIntrinsicHeight(double width);
  bool isDescendantOf(CanvasParentState parent);
  Path getPath();
  void markForDisposal();
  bool get markedForDisposal;
  void markForRebuild();
  void dispose();
  void putReorderOffset(CanvasItemState child, double offset);
  void removeReorderOffset(CanvasItemState child);
  void clearReorderOffsets();
  Offset? get reorderOffsets;
  int? get targetReorderIndex;
  set targetReorderIndex(int? value);
  CanvasParentState? get targetReparent;
  set targetReparent(CanvasParentState? value);
  Offset? get dragOffset;
  set dragOffset(Offset? value);
}

abstract class CanvasParent extends CanvasItem {
  List<LayoutGrid> get layoutGrids;
  set layoutGrids(List<LayoutGrid> value);

  List<CanvasItem> get children;
  set children(List<CanvasItem> value);

  CanvasLayout get layout;
  set layout(CanvasLayout value);

  bool get clipContent;
  set clipContent(bool value);

  @override
  CanvasParentState createState({CanvasParentState? parent});

  @override
  List<CanvasParentState> get attachedStates;

  @override
  void attach(covariant CanvasParentState state);

  @override
  void detach(covariant CanvasParentState state);

  // helper
  void addChild(CanvasItem child);
  void removeChild(CanvasItem child);
  void insertChild(int index, CanvasItem child);
  void removeChildAt(int index);
  void clearChildren();
  void insertBefore(CanvasItem child, CanvasItem beforeChild);
}

abstract class CanvasParentState extends CanvasItemState {
  @override
  CanvasParentItemEditorData get editorData;
  @override
  set editorData(covariant CanvasParentItemEditorData value);
  @override
  CanvasParent get item;

  List<CanvasItemState> get children;
  set children(List<CanvasItemState> value);

  void buildChildren(List<CanvasItem> children);

  CanvasItemState? get firstChild;
  CanvasItemState? get lastChild;

  LinkedNode<CanvasItemState>? get firstChildNode;
  LinkedNode<CanvasItemState>? get lastChildNode;

  void reorderItem(CanvasItemState child, int newIndex);

  bool hitTestChildren(CanvasHitTestResult result, Offset position);
  void selectTestChildren(CanvasHitTestResult result, Path path);

  // Editor purpose
  EdgeInsets analyzePossiblePadding();
  Axis analyzePossibleFlexDirection();
  double analyzePossibleSpacing();

  Selection? get targetDrop;
  set targetDrop(Selection? value);
}

class CanvasItemEditorData {
  final Offset? dragOffset;
  final Map<CanvasItemState, double> reorderOffsetMap;
  final CanvasParentState? targetReparent;
  final int? targetReorderIndex;

  const CanvasItemEditorData({
    required this.dragOffset,
    required this.reorderOffsetMap,
    required this.targetReparent,
    required this.targetReorderIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CanvasItemEditorData) return false;
    return dragOffset == other.dragOffset &&
        reorderOffsetMap == other.reorderOffsetMap &&
        targetReparent == other.targetReparent &&
        targetReorderIndex == other.targetReorderIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      dragOffset,
      reorderOffsetMap,
      targetReparent,
      targetReorderIndex,
    );
  }
}

class CanvasParentItemEditorData extends CanvasItemEditorData {
  final Selection? targetDrop;

  const CanvasParentItemEditorData({
    required super.dragOffset,
    required super.reorderOffsetMap,
    required super.targetReparent,
    required this.targetDrop,
    required super.targetReorderIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CanvasParentItemEditorData) return false;
    return super == other && targetDrop == other.targetDrop;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      targetDrop,
    );
  }
}

enum CanvasOverflow {
  none,
  scrollHorizontal,
  scrollVertical,
  scroll,
}
