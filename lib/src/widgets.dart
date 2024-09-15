import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/rendering.dart';
import 'package:flutter/widgets.dart';

class CanvasItem extends StatelessWidget {
  final CanvasTransform transform;
  final Widget background;
  final List<Widget> children;
  final List<Widget> controls;

  const CanvasItem({
    super.key,
    required this.transform,
    required this.background,
    this.children = const [],
    this.controls = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: transform.matrix,
      child: CanvasGroup(
        controls: controls,
        children: [
          ConstrainedCanvasItem(
            transform: transform.size,
            child: background,
          ),
          ...children,
        ],
      ),
    );
  }
}

class CanvasGroup extends MultiChildRenderObjectWidget {
  CanvasGroup({
    super.key,
    required List<Widget> children,
    List<Widget> controls = const [],
    this.clipBehavior = Clip.none,
  }) : super(children: [...children, ...controls]);

  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCanvasGroup(clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCanvasGroup renderObject) {
    renderObject.clipBehavior = clipBehavior;
  }
}

class ConstrainedCanvasItem extends SingleChildRenderObjectWidget {
  final Size transform;

  const ConstrainedCanvasItem({
    super.key,
    required this.transform,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderConstrainedCanvasItem(transform: transform);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedCanvasItem renderObject) {
    renderObject.transform = transform;
  }
}
