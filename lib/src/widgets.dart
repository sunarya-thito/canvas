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
        return ListenableBuilder(
          listenable: controller.rootNode.item.childrenNotifier,
          builder: (context, child) {
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
          },
        );
      }),
    );
  }
}

class CanvasNodeWidget extends StatelessWidget {
  final CanvasItemNode node;

  const CanvasNodeWidget({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: Listenable.merge({
          node.item.transformNotifier,
          node.item.childrenNotifier,
        }),
        child: ListenableBuilder(
          listenable: node.item.widgetNotifier,
          builder: (context, child) {
            return node.item.widget ?? const SizedBox();
          },
        ),
        builder: (context, background) {
          return CanvasTransformed(
            matrix4: node.item.transform.computeMatrix(node),
            size: node.item.transform.size,
            background: background!,
            children:
                node.children.map((e) => CanvasNodeWidget(node: e)).toList(),
          );
        });
  }
}

class CanvasTransformed extends StatelessWidget {
  final Matrix4 matrix4;
  final Size size;
  final Widget background;
  final List<Widget> children;

  const CanvasTransformed({
    super.key,
    required this.matrix4,
    required this.size,
    required this.background,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: matrix4,
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
