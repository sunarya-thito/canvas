import 'package:flutter/widgets.dart';

import '../canvas.dart';

class CanvasViewportWidget extends StatelessWidget {
  final CanvasViewport controller;
  final ResizeMode resizeMode;
  final TransformControl control;

  const CanvasViewportWidget({
    super.key,
    required this.controller,
    this.resizeMode = ResizeMode.resize,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, constraints) {
        return GroupWidget(
          children: [
            CanvasTransformed(
              matrix4: Matrix4.identity()
                ..translate(constraints.biggest.width / 2,
                    constraints.biggest.height / 2),
              size: constraints.biggest,
              background: GroupWidget(
                children: [
                  CanvasNodeWidget(node: controller.rootNode),
                  TransformControlWidget(
                    node: controller.rootNode,
                    control: control,
                    resizeMode: resizeMode,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CanvasNodeWidget extends StatefulWidget {
  final CanvasItemNode node;

  const CanvasNodeWidget({
    super.key,
    required this.node,
  });

  @override
  State<CanvasNodeWidget> createState() => _CanvasNodeWidgetState();
}

class _CanvasNodeWidgetState extends State<CanvasNodeWidget> {
  @override
  void initState() {
    super.initState();
    widget.node.initState();
  }

  @override
  void didUpdateWidget(covariant CanvasNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node != oldWidget.node) {
      oldWidget.node.dispose();
      widget.node.initState();
    }
  }

  @override
  void dispose() {
    widget.node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: Listenable.merge({
          widget.node.item,
          widget.node.matrixNotifier,
          widget.node.sizeNotifier,
          widget.node.item.childrenNotifier,
        }),
        child: widget.node.item.build(context),
        builder: (context, background) {
          return CanvasTransformed(
            matrix4: widget.node.matrix,
            size: widget.node.size,
            background: Transform.scale(
              alignment: Alignment.topLeft,
              scaleX: widget.node.item.transform.scale.width,
              scaleY: widget.node.item.transform.scale.height,
              child: background!,
            ),
            children: widget.node.children
                .map((e) => CanvasNodeWidget(node: e))
                .toList(),
          );
        });
  }
}

class CanvasTransformed extends StatelessWidget {
  final Matrix4 matrix4;
  final Size size;
  final Widget background;
  final List<Widget> children;
  final bool transformHitTests;

  const CanvasTransformed({
    super.key,
    required this.matrix4,
    required this.size,
    required this.background,
    this.transformHitTests = true,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: matrix4,
      transformHitTests: transformHitTests,
      child: GroupWidget(
        children: [
          ConstrainedCanvasItem(
            transform: size,
            child: background,
          ),
          ...children,
        ],
      ),
    );
  }
}

class GroupWidget extends MultiChildRenderObjectWidget {
  GroupWidget({
    super.key,
    required List<Widget> children,
    this.clipBehavior = Clip.none,
  }) : super(children: [...children]);

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
