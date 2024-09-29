import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:flutter/widgets.dart';

import '../canvas.dart';

class CanvasController implements Listenable {
  final RootCanvasItem _root = RootCanvasItem(
    layout: AbsoluteLayout(),
  );

  CanvasController({List<CanvasItem> children = const []}) {
    _root.children = children;
  }

  List<CanvasItem> get children => _root.children;
  set children(List<CanvasItem> children) => _root.children = children;

  @override
  void addListener(listener) {
    _root.layoutNotifier.addListener(listener);
    _root.childrenNotifier.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _root.layoutNotifier.removeListener(listener);
    _root.childrenNotifier.removeListener(listener);
  }
}

class TransformSession {
  final List<TransformNode> nodes;

  TransformSession(this.nodes);

  void visit(void Function(TransformNode node) visitor) {
    for (var node in nodes) {
      visitor(node);
    }
  }

  void apply() {
    for (var node in nodes) {
      if (node.newLayout != null && node.newLayout != node.layout) {
        node.item.layout = node.newLayout!;
      }
    }
  }

  void reset() {
    for (var node in nodes) {
      node.item.layout = node.layout;
    }
  }
}

class TransformNode {
  final CanvasItem item;
  final LayoutTransform transform;
  final LayoutTransform? parentTransform;
  final Layout layout;
  Layout? newLayout;

  TransformNode(this.item, this.transform, this.parentTransform, this.layout);
}

class CanvasViewportData extends InheritedWidget {
  final CanvasController controller;
  final ResizeMode resizeMode;
  final TransformControl transformControl;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;

  const CanvasViewportData({
    Key? key,
    required this.controller,
    required this.resizeMode,
    required this.transformControl,
    required this.multiSelect,
    required this.symmetricResize,
    required this.proportionalResize,
    required Widget child,
  }) : super(key: key, child: child);

  void visit(void Function(CanvasItem item) visitor) {
    controller._root.visit(visitor);
  }

  void visitWithTransform(
      void Function(CanvasItem item, LayoutTransform? parentTransform) visitor,
      {bool rootSelectionOnly = false}) {
    controller._root
        .visitWithTransform(visitor, rootSelectionOnly: rootSelectionOnly);
  }

  TransformSession beginTransform(
      {bool rootSelectionOnly = false, bool selectedOnly = true}) {
    final nodes = <TransformNode>[];
    visitWithTransform((item, parentTransform) {
      if (item.selected || !selectedOnly) {
        nodes.add(
            TransformNode(item, item.transform, parentTransform, item.layout));
      }
    }, rootSelectionOnly: rootSelectionOnly);
    return TransformSession(nodes);
  }

  static CanvasViewportData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CanvasViewportData>()!;
  }

  @override
  bool updateShouldNotify(covariant CanvasViewportData oldWidget) {
    return oldWidget.controller != controller ||
        oldWidget.resizeMode != resizeMode ||
        oldWidget.transformControl != transformControl ||
        oldWidget.multiSelect != multiSelect ||
        oldWidget.symmetricResize != symmetricResize ||
        oldWidget.proportionalResize != proportionalResize;
  }
}

enum ResizeMode { resize, scale }

class CanvasViewport extends StatelessWidget {
  final CanvasController controller;
  final AlignmentGeometry alignment;
  final TransformControl transformControl;
  final ResizeMode resizeMode;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;

  const CanvasViewport({
    Key? key,
    required this.controller,
    this.alignment = Alignment.center,
    this.transformControl = const StandardTransformControl(),
    this.resizeMode = ResizeMode.resize,
    this.multiSelect = false,
    this.symmetricResize = false,
    this.proportionalResize = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textDirection = Directionality.of(context);
    var resolvedAlignment = alignment.resolve(textDirection);
    return LayoutBuilder(
      builder: (context, constraints) {
        var offset = resolvedAlignment.alongSize(constraints.biggest);
        return Transform.translate(
          offset: offset,
          child: GroupWidget(
            children: [
              CanvasItemWidget(item: controller._root),
              CanvasViewportData(
                controller: controller,
                resizeMode: resizeMode,
                transformControl: transformControl,
                multiSelect: multiSelect,
                symmetricResize: symmetricResize,
                proportionalResize: proportionalResize,
                child: transformControl.build(context, controller._root),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CanvasItemWidget extends StatefulWidget {
  final CanvasItem? parent;
  final CanvasItem item;

  const CanvasItemWidget({
    Key? key,
    this.parent,
    required this.item,
  }) : super(key: key);

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  @override
  void initState() {
    super.initState();
    widget.item.layoutNotifier.addListener(_onLayoutChanged);
    _onLayoutChanged();
  }

  void _onLayoutChanged() {
    if (widget.parent?.layout.shouldHandleChildLayout == true) {
      widget.parent!.layoutNotifier.value.performLayout(widget.parent!);
      return;
    }
    widget.item.layoutNotifier.value.performLayout(widget.item);
  }

  @override
  void dispose() {
    widget.item.layoutNotifier.removeListener(_onLayoutChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? background = widget.item.build(context);
    return ListenableBuilder(
        listenable: widget.item.transformNotifier,
        builder: (context, child) {
          var layoutTransform = widget.item.transform;
          return Transform.translate(
            offset: layoutTransform.offset,
            child: Transform.rotate(
              angle: layoutTransform.rotation,
              alignment: Alignment.topLeft,
              child: GroupWidget(
                children: [
                  if (background != null)
                    Transform.scale(
                      scaleX: layoutTransform.scale.dx,
                      scaleY: layoutTransform.scale.dy,
                      alignment: Alignment.topLeft,
                      child: Box(
                        size: layoutTransform.size,
                        child: background,
                      ),
                    ),
                  ListenableBuilder(
                    listenable: widget.item.childrenNotifier,
                    builder: (context, child) {
                      return GroupWidget(
                        children: widget.item.children.map((child) {
                          return CanvasItemWidget(
                            item: child,
                            parent: widget.item,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}

extension SizeExtension on Size {
  Size abs() {
    return Size(width.abs(), height.abs());
  }
}
