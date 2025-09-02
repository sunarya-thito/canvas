import 'dart:math';
import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/item/widget/frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CanvasFrame extends CanvasParent {
  CanvasLayout _layout;
  List<LayoutGrid> _layoutGrids;
  bool _clipContent;

  CanvasFrame({
    super.layoutData,
    super.locked,
    super.debugLabel,
    super.children,
    CanvasLayout layout = const FixedLayout(),
    List<LayoutGrid> layoutGrids = const [],
    bool clipContent = false,
  })  : _layout = layout,
        _layoutGrids = List.of(layoutGrids),
        _clipContent = clipContent;

  CanvasLayout get layout => _layout;
  set layout(CanvasLayout value) {
    if (_layout != value) {
      _layout = value;
      notifyStates();
    }
  }

  List<LayoutGrid> get layoutGrids => List.unmodifiable(_layoutGrids);
  set layoutGrids(List<LayoutGrid> value) {
    if (!listEquals(_layoutGrids, value)) {
      _layoutGrids = List.of(value);
      notifyStates();
    }
  }

  bool get clipContent => _clipContent;
  set clipContent(bool value) {
    if (_clipContent != value) {
      _clipContent = value;
      notifyStates();
    }
  }

  @override
  CanvasFrameState createState({CanvasParentState? parent}) {
    return CanvasFrameState(item: this, parent: parent);
  }
}

class CanvasFrameState extends CanvasParentState {
  CanvasFrameState({required super.item, required super.parent});

  @override
  CanvasFrame get item => super.item as CanvasFrame;

  @override
  CanvasParentData setupParentData(
      CanvasItemState child, CanvasParentData? parentData) {
    return item.layout.setupParentData(this, child, parentData);
  }

  @override
  Widget renderParent(BuildContext context, List<Widget> children) {
    return CanvasFrameWidget(
      item: this,
      children: children,
    );
  }

  Color _generateColor(int hash) {
    Random random = Random(hash);
    return HSVColor.fromAHSV(
      1.0,
      random.nextInt(360).toDouble(),
      0.8,
      0.8,
    ).toColor();
  }

  @override
  Widget? renderContent(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: BoxDecoration(
          color: _generateColor(item.hashCode),
          border: Border.all(
            color: Color.fromARGB(115, 0, 0, 0),
            width: 2,
          ),
        ),
        child: Text(
          'Frame (${item.debugLabel})',
        ),
      );
    });
  }

  @override
  Size forceLayout(Size size) {
    var result = item.layout.performLayout(this, size);
    // return super.forceLayout(size);
    return result;
  }
}
