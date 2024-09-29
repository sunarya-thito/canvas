import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/widgets.dart';

import '../canvas.dart';

class CanvasController implements Listenable {
  final RootCanvasItem _root = RootCanvasItem(
    layout: const AbsoluteLayout(),
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

class CanvasHitTestEntry {
  final CanvasItem item;
  final Offset localPosition;

  CanvasHitTestEntry(this.item, this.localPosition);
}

class CanvasHitTestResult {
  final List<CanvasHitTestEntry> path = [];
}

class CanvasViewportData extends InheritedWidget {
  final CanvasController controller;
  final ResizeMode resizeMode;
  final TransformControl transformControl;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;
  final bool anchoredRotate;
  final EventConsumer<ReparentDetails>? onReparent;

  const CanvasViewportData({
    super.key,
    required this.controller,
    required this.resizeMode,
    required this.transformControl,
    required this.multiSelect,
    required this.symmetricResize,
    required this.proportionalResize,
    required this.anchoredRotate,
    required this.onReparent,
    required super.child,
  });

  void visit(void Function(CanvasItem item) visitor) {
    controller._root.visit(visitor);
  }

  void visitWithTransform(
      void Function(CanvasItem item, LayoutTransform? parentTransform) visitor,
      {bool rootSelectionOnly = false}) {
    controller._root
        .visitWithTransform(visitor, rootSelectionOnly: rootSelectionOnly);
  }

  void visitSnappingPoints(void Function(SnappingPoint snappingPoint) visitor) {
    controller._root.visitSnappingPoints(visitor);
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    controller._root.hitTest(result, position);
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

typedef EventConsumer<T> = bool Function(T details);

class CanvasViewport extends StatelessWidget {
  final CanvasController controller;
  final AlignmentGeometry alignment;
  final TransformControl transformControl;
  final ResizeMode resizeMode;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;
  final bool anchoredRotate;
  final EventConsumer<ReparentDetails>? onReparent;

  const CanvasViewport({
    super.key,
    required this.controller,
    this.alignment = Alignment.center,
    this.transformControl = const StandardTransformControl(),
    this.resizeMode = ResizeMode.resize,
    this.multiSelect = false,
    this.symmetricResize = false,
    this.proportionalResize = false,
    this.anchoredRotate = false,
    this.onReparent,
  });

  @override
  Widget build(BuildContext context) {
    var textDirection = Directionality.of(context);
    var resolvedAlignment = alignment.resolve(textDirection);
    return ClipRect(
      child: CanvasViewportData(
        controller: controller,
        resizeMode: resizeMode,
        transformControl: transformControl,
        multiSelect: multiSelect,
        symmetricResize: symmetricResize,
        proportionalResize: proportionalResize,
        anchoredRotate: anchoredRotate,
        onReparent: onReparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            var offset = resolvedAlignment.alongSize(constraints.biggest);
            return Transform.translate(
              offset: offset,
              child: GroupWidget(
                children: [
                  CanvasItemWidget(item: controller._root),
                  _CanvasItemBoundingBox(
                    item: controller._root,
                    node: controller._root.toNode(),
                  ),
                  transformControl.build(context, controller._root),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CanvasItemNode {
  final CanvasItemNode? parent;
  final CanvasItem item;
  final List<CanvasItemNode> children = [];

  CanvasItemNode(this.parent, this.item);

  void initState() {
    item.childrenNotifier.addListener(_handleChildrenChanged);
    _handleChildrenChanged();
  }

  void _handleChildrenChanged() {
    children.clear();
    for (var child in item.children) {
      children.add(child.toNode(this));
    }
  }

  void dispose() {
    item.childrenNotifier.removeListener(_handleChildrenChanged);
  }

  Offset toGlobal(Offset local) {
    CanvasItemNode? current = this;
    while (current != null) {
      local = current.item.transform.transformToParent(local);
      current = current.parent;
    }
    return local;
  }

  Offset toLocal(Offset global) {
    CanvasItemNode? current = this;
    while (current != null) {
      global = current.item.transform.transformFromParent(global);
      current = current.parent;
    }
    return global;
  }

  bool contains(Offset localPosition) {
    var scaledSize = item.transform.scaledSize;
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= scaledSize.width &&
        localPosition.dy <= scaledSize.height;
  }
}

class _CanvasItemBoundingBox extends StatefulWidget {
  final CanvasItem item;
  final double parentRotation;
  final CanvasItemNode node;

  const _CanvasItemBoundingBox({
    required this.item,
    this.parentRotation = 0,
    required this.node,
  });

  @override
  State<_CanvasItemBoundingBox> createState() => _CanvasItemBoundingBoxState();
}

class _CanvasItemBoundingBoxState extends State<_CanvasItemBoundingBox> {
  TransformSession? _session;
  Offset? _totalOffset;

  double get globalRotation {
    return widget.item.transform.rotation + widget.parentRotation;
  }

  @override
  void initState() {
    super.initState();
    widget.node.initState();
  }

  @override
  void didUpdateWidget(covariant _CanvasItemBoundingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
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
    CanvasViewportData viewportData = CanvasViewportData.of(context);
    return ListenableBuilder(
      listenable: widget.item.transformNotifier,
      builder: (context, child) {
        var transform = widget.item.transform;
        var size = transform.scaledSize;
        Offset flipOffset = Offset(
          size.width < 0 ? size.width : 0,
          size.height < 0 ? size.height : 0,
        );
        size = size.abs();
        return Transform.translate(
          offset: transform.offset,
          child: Transform.rotate(
            angle: transform.rotation,
            alignment: Alignment.topLeft,
            child: GroupWidget(
              children: [
                Transform.translate(
                  offset: flipOffset,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (viewportData.multiSelect) {
                        widget.item.selected = !widget.item.selected;
                      } else {
                        viewportData.visit(
                          (item) {
                            item.selected = item == widget.item;
                          },
                        );
                      }
                    },
                    child: PanGesture(
                      onPanStart: (details) {
                        if (!widget.item.selected) {
                          if (viewportData.multiSelect) {
                            widget.item.selected = !widget.item.selected;
                          } else {
                            viewportData.visit(
                              (item) {
                                item.selected = item == widget.item;
                              },
                            );
                          }
                        }
                        _session = viewportData.beginTransform(
                            rootSelectionOnly: true);
                        _totalOffset = Offset.zero;
                      },
                      onPanUpdate: (details) {
                        Offset delta = details.delta;
                        delta = rotatePoint(delta, globalRotation);
                        _totalOffset = _totalOffset! + delta;
                        _session!.visit(
                          (node) {
                            Offset localDelta = _totalOffset!;
                            if (node.parentTransform != null) {
                              localDelta = rotatePoint(
                                  localDelta, -node.parentTransform!.rotation);
                            }
                            node.newLayout = node.layout.drag(localDelta);
                          },
                        );
                        _session!.apply();
                      },
                      onPanEnd: (details) {
                        _session = null;
                        _totalOffset = null;
                        // CanvasHitTestResult result = CanvasHitTestResult();
                        // var position =
                        //     widget.node.toGlobal(details.localPosition);
                        // viewportData.hitTest(result, position);
                      },
                      onPanCancel: () {
                        if (_session != null) {
                          _session!.reset();
                          _session = null;
                        }
                        _totalOffset = null;
                      },
                      child: MetaData(
                        metaData: this,
                        child: SizedBox.fromSize(
                          size: size,
                        ),
                      ),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: widget.item.childrenNotifier,
                  builder: (context, child) {
                    return GroupWidget(
                      children: [
                        for (var child in widget.node.children)
                          _CanvasItemBoundingBox(
                            item: child.item,
                            parentRotation: globalRotation,
                            node: child,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
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
    super.key,
    this.parent,
    required this.item,
  });

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
