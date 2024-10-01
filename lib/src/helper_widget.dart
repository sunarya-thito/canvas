import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GroupWidget extends MultiChildRenderObjectWidget {
  const GroupWidget({
    super.key,
    super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGroup();
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGroup renderObject) {
    renderObject.markNeedsLayout();
  }
}

class GroupParentData extends ContainerBoxParentData<RenderBox> {}

class RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  static const double _bigSize = 999999999999999;
  static const BoxConstraints _bigConstraints = BoxConstraints(
    maxWidth: _bigSize,
    maxHeight: _bigSize,
  );
  RenderGroup({
    List<RenderBox>? children,
  }) {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      child.layout(_bigConstraints);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      final childHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (childHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as GroupParentData;
      context.paintChild(child, offset + childParentData.offset);
      child = childParentData.nextSibling;
    }
  }
}

class PanGesture extends StatefulWidget {
  final void Function(DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final void Function()? onPanCancel;
  final Widget? child;

  const PanGesture({
    super.key,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.child,
  });

  @override
  State<PanGesture> createState() => _PanGestureState();
}

class _PanGestureState extends State<PanGesture> {
  final FocusNode _focusNode = FocusNode();
  bool _cancel = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          _cancel = true;
          widget.onPanCancel?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          _focusNode.requestFocus();
          _cancel = false;
          widget.onPanStart?.call(details);
        },
        onPanUpdate: (details) {
          if (_cancel) {
            return;
          }
          widget.onPanUpdate?.call(details);
        },
        onPanEnd: (details) {
          if (_cancel) {
            return;
          }
          widget.onPanEnd?.call(details);
        },
        onPanCancel: () {
          _cancel = true;
          widget.onPanCancel?.call();
        },
        child: widget.child,
      ),
    );
  }
}

class MousePanGesture extends StatefulWidget {
  static const int primaryButton = kPrimaryButton;
  static const int secondaryButton = kSecondaryButton;
  static const int tertiaryButton = kTertiaryButton; // Middle button
  final int button;
  final void Function(DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final void Function()? onPanCancel;
  final Widget? child;
  final HitTestBehavior behavior;

  const MousePanGesture({
    super.key,
    this.button = 0,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior = HitTestBehavior.translucent,
    this.child,
  });

  @override
  State<MousePanGesture> createState() => _MousePanGestureState();
}

class _MousePanGestureState extends State<MousePanGesture> {
  final FocusNode _focusNode = FocusNode();
  bool _cancel = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          _cancel = true;
          widget.onPanCancel?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: RawGestureDetector(
        behavior: widget.behavior,
        gestures: {
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(
              debugOwner: this,
              allowedButtonsFilter: (buttons) => buttons & widget.button != 0,
            ),
            (instance) {
              instance
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = (details) {
                  _focusNode.requestFocus();
                  _cancel = false;
                  widget.onPanStart?.call(details);
                }
                ..onUpdate = (details) {
                  if (_cancel) {
                    return;
                  }
                  widget.onPanUpdate?.call(details);
                }
                ..onEnd = (details) {
                  if (_cancel) {
                    return;
                  }
                  widget.onPanEnd?.call(details);
                }
                ..onCancel = () {
                  _cancel = true;
                  widget.onPanCancel?.call();
                };
            },
          )
        },
        child: widget.child,
      ),
    );
  }
}

class Box extends StatelessWidget {
  final Size size;
  final Widget child;

  const Box({
    super.key,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    double flipX = size.width < 0 ? -1 : 1;
    double flipY = size.height < 0 ? -1 : 1;
    return Transform.scale(
      scaleX: flipX,
      scaleY: flipY,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: size.width.abs(),
        height: size.height.abs(),
        child: child,
      ),
    );
  }
}

class AlwaysHitBox extends LeafRenderObjectWidget {
  const AlwaysHitBox({
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAlwaysHitBox();
  }
}

class RenderAlwaysHitBox extends RenderBox {
  RenderAlwaysHitBox();

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return true;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }
}
