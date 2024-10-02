import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../canvas.dart';

class CanvasViewportThemeData {
  final Color backgroundColor;
  final Decoration canvasDecoration;
  final Decoration selectionDecoration;

  const CanvasViewportThemeData({
    this.backgroundColor = const Color(0xFFB0B0B0),
    this.canvasDecoration = const BoxDecoration(
      color: Color(0xFFFFFFFF),
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    this.selectionDecoration = const BoxDecoration(
      color: Color(0x806E91E1),
      border: Border(
        top: BorderSide(color: Color(0xFF6E91E1), width: 1),
        left: BorderSide(color: Color(0xFF6E91E1), width: 1),
        right: BorderSide(color: Color(0xFF6E91E1), width: 1),
        bottom: BorderSide(color: Color(0xFF6E91E1), width: 1),
      ),
    ),
  });
}

class CanvasController implements Listenable, CanvasParent {
  final RootCanvasItem _root = RootCanvasItem(
    layout: const AbsoluteLayout(),
  );

  CanvasController({List<CanvasItem> children = const []}) {
    _root.children = children;
  }

  void hitTestSelection(CanvasHitTestResult result, Polygon selection,
      [SelectionBehavior behavior = SelectionBehavior.overlap]) {
    _root.hitTestSelection(result, selection, behavior);
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    _root.hitTest(result, position);
  }

  void visitTo(CanvasItem target, void Function(CanvasItem item) visitor) {
    _root.visitTo(target, visitor);
  }

  @override
  List<CanvasItem> get children => _root.children;
  set children(List<CanvasItem> children) => _root.children = children;

  @override
  void addListener(listener) {
    _root.layoutListenable.addListener(listener);
    _root.childListenable.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _root.layoutListenable.removeListener(listener);
    _root.childListenable.removeListener(listener);
  }

  @override
  void addChild(CanvasItem child) {
    _root.addChild(child);
  }

  @override
  void removeChild(CanvasItem child) {
    _root.removeChild(child);
  }

  @override
  void addChildren(List<CanvasItem> children) {
    _root.addChildren(children);
  }

  @override
  void removeChildren(List<CanvasItem> children) {
    _root.removeChildren(children);
  }

  @override
  void insertChild(int index, CanvasItem child) {
    _root.insertChild(index, child);
  }

  @override
  void removeChildAt(int index) {
    _root.removeChildAt(index);
  }

  @override
  ValueListenable<List<CanvasItem>> get childListenable =>
      _root.childListenable;

  CanvasItem get root => _root;
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

  void apply() {
    if (newLayout != null && newLayout != item.layout) {
      item.layout = newLayout!;
    }
  }
}

class CanvasHitTestEntry {
  final CanvasItem item;
  final Offset localPosition;

  CanvasHitTestEntry(this.item, this.localPosition);

  @override
  String toString() {
    return 'CanvasHitTestEntry(item: $item, localPosition: $localPosition)';
  }
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
  final EventPredicate<ReparentDetails>? onReparent;
  final Offset offset;
  final double zoom;
  final SnappingConfiguration snapping;
  final CanvasItem? hoveredItem;

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
    required this.offset,
    required this.zoom,
    required this.snapping,
    required this.hoveredItem,
    required super.child,
  });

  void fillInSnappingPoints(LayoutSnapping layoutSnapping) {
    visitSnappingPoints(
      (snappingPoint) {
        layoutSnapping.snappingPoints.add(snappingPoint);
      },
    );
  }

  void visit(void Function(CanvasItem item) visitor) {
    controller._root.visit(visitor);
  }

  void hitTest(CanvasHitTestResult result, Offset position) {
    controller._root.hitTest(result, position);
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
        oldWidget.proportionalResize != proportionalResize ||
        oldWidget.anchoredRotate != anchoredRotate ||
        oldWidget.onReparent != onReparent ||
        oldWidget.offset != offset ||
        oldWidget.zoom != zoom ||
        oldWidget.snapping != snapping ||
        oldWidget.hoveredItem != hoveredItem;
  }
}

enum ResizeMode { resize, scale }

typedef EventPredicate<T> = bool Function(T details);
typedef EventConsumer<T> = void Function(T details);

class CanvasViewport extends StatefulWidget {
  final CanvasController controller;
  final Alignment alignment;
  final TransformControl transformControl;
  final ResizeMode resizeMode;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;
  final bool anchoredRotate;
  final EventPredicate<ReparentDetails>? onReparent;
  final EventConsumer<CanvasTransform>? onTransform;
  final CanvasTransform initialTransform;
  final CanvasGestures gestures;
  final SnappingConfiguration snapping;
  final CanvasSelectionHandler? selectionHandler;
  final SelectionBehavior selectionBehavior;
  final Size canvasSize;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<CanvasSelectSession>? onSelectionStart;
  final ValueChanged<CanvasSelectSession>? onSelectionChange;
  final ValueChanged<CanvasSelectSession>? onSelectionEnd;
  final VoidCallback? onSelectionCancel;

  const CanvasViewport({
    super.key,
    required this.controller,
    this.minZoom = 0.1,
    this.maxZoom = 5,
    this.alignment = Alignment.center,
    this.transformControl = const StandardTransformControl(),
    this.resizeMode = ResizeMode.resize,
    this.multiSelect = false,
    this.symmetricResize = false,
    this.proportionalResize = false,
    this.anchoredRotate = false,
    this.onReparent,
    this.onTransform,
    this.initialTransform = const CanvasTransform(),
    this.gestures = const DesktopCanvasGestures(),
    this.snapping = const SnappingConfiguration(),
    this.selectionHandler,
    this.selectionBehavior = SelectionBehavior.contain,
    this.canvasSize = Size.zero,
    this.onSelectionStart,
    this.onSelectionChange,
    this.onSelectionEnd,
    this.onSelectionCancel,
  });

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends State<CanvasViewport>
    implements CanvasViewportHandle {
  /// to preserve state and to prevent unnecessary rebuilds
  final GlobalKey _viewportKey = GlobalKey();
  CanvasItem? _hoveredItem;
  late CanvasTransform _transform;
  late Offset _canvasOffset;
  late Size _size;

  final ValueNotifier<CanvasSelectSession?> _selectNotifier =
      ValueNotifier(null);
  CanvasSelectionSession? _selectSession;

  @override
  void initState() {
    super.initState();
    _transform = widget.initialTransform;
  }

  @override
  Size get size => _size;

  @override
  bool get enableInstantSelection => widget.selectionHandler != null;

  @override
  void instantSelection(Offset position) {
    if (widget.selectionHandler != null) {
      widget.selectionHandler!.onInstantSelection(position);
    }
  }

  @override
  void drag(Offset delta) {
    setState(() {
      _transform = CanvasTransform(
        offset: _transform.offset + delta,
        zoom: _transform.zoom,
      );
    });
  }

  @override
  void zoomAt(Offset position, double delta) {
    delta = delta * _transform.zoom;
    position = position - widget.alignment.alongSize(widget.canvasSize);
    var currentZoom = _transform.zoom;
    if (currentZoom + delta < widget.minZoom) {
      delta = widget.minZoom - currentZoom;
    }
    if (currentZoom + delta > widget.maxZoom) {
      delta = widget.maxZoom - currentZoom;
    }
    setState(() {
      _transform = CanvasTransform(
        offset: _transform.offset - position * delta,
        zoom: currentZoom + delta,
      );
    });
  }

  @override
  Offset get canvasOffset => _canvasOffset;

  @override
  CanvasTransform get transform => _transform;

  @override
  set transform(CanvasTransform value) {
    setState(() {
      _transform = value;
    });
  }

  bool get _shouldCancelObjectDragging =>
      widget.selectionHandler?.shouldCancelObjectDragging == true;

  Widget _wrapGestures(BuildContext context, Widget child) {
    if (_shouldCancelObjectDragging) {
      return KeyedSubtree(
        key: _viewportKey,
        child: child,
      );
    }
    return widget.gestures.wrapViewport(
        context,
        KeyedSubtree(
          key: _viewportKey,
          child: child,
        ),
        this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CanvasViewportThemeData();
    var textDirection = Directionality.of(context);
    var resolvedAlignment = widget.alignment.resolve(textDirection);
    var canvasOffset = resolvedAlignment.alongSize(widget.canvasSize);
    return ColoredBox(
      color: theme.backgroundColor,
      child: LayoutBuilder(builder: (context, constraints) {
        var offset = resolvedAlignment.alongSize(constraints.biggest);
        _canvasOffset =
            offset + _transform.offset - canvasOffset * _transform.zoom;
        _size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            widget.controller._root.visit(
              (item) {
                item.selected = false;
              },
            );
          },
          child: _wrapGestures(
            context,
            Stack(
              fit: StackFit.passthrough,
              children: [
                ClipRect(
                  child: CanvasViewportData(
                    offset: _transform.offset,
                    zoom: _transform.zoom,
                    controller: widget.controller,
                    resizeMode: widget.resizeMode,
                    transformControl: widget.transformControl,
                    multiSelect: widget.multiSelect,
                    symmetricResize: widget.symmetricResize,
                    proportionalResize: widget.proportionalResize,
                    anchoredRotate: widget.anchoredRotate,
                    onReparent: widget.onReparent,
                    snapping: widget.snapping,
                    hoveredItem: _hoveredItem,
                    child: Transform.translate(
                      offset: offset +
                          _transform.offset -
                          canvasOffset * _transform.zoom,
                      child: GroupWidget(
                        children: [
                          Transform.scale(
                            alignment: Alignment.topLeft,
                            scale: _transform.zoom,
                            child: CanvasItemWidget(
                              background: widget.canvasSize.isEmpty
                                  ? null
                                  : Container(
                                      width: widget.canvasSize.width,
                                      height: widget.canvasSize.height,
                                      decoration: theme.canvasDecoration,
                                    ),
                              item: widget.controller._root,
                            ),
                          ),
                          Transform.scale(
                            alignment: Alignment.topLeft,
                            scale: _transform.zoom,
                            child: _CanvasItemBoundingBox(
                              item: widget.controller._root,
                              node: widget.controller._root.toNode(),
                              onHover: (item, hovered) {
                                if (hovered) {
                                  if (_hoveredItem != item) {
                                    setState(() {
                                      _hoveredItem = item;
                                    });
                                  }
                                } else {
                                  if (_hoveredItem == item) {
                                    setState(() {
                                      _hoveredItem = null;
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                          if (widget.selectionHandler == null)
                            ListenableBuilder(
                              listenable: _selectNotifier,
                              builder: (context, child) {
                                var session = _selectNotifier.value;
                                if (session == null) {
                                  return const SizedBox();
                                }
                                Rect rect = Rect.fromPoints(
                                    session.startPosition, session.endPosition);
                                return Transform.translate(
                                  offset: rect.topLeft,
                                  child: Container(
                                    width: rect.width,
                                    height: rect.height,
                                    decoration: theme.selectionDecoration,
                                  ),
                                );
                              },
                            ),
                          widget.transformControl
                              .build(context, widget.controller._root.toNode()),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_shouldCancelObjectDragging)
                  Positioned.fill(
                    child: widget.gestures
                        .wrapViewport(context, const SizedBox(), this),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void cancelSelectSession() {
    if (_selectSession != null) {
      _selectSession!.onSelectionCancel();
      _selectSession = null;
    }
    _selectNotifier.value = null;
    widget.onSelectionCancel?.call();
  }

  @override
  void endSelectSession() {
    var current = _selectNotifier.value;
    if (current != null) {
      widget.onSelectionEnd?.call(current);
      _selectNotifier.value = null;
      if (_selectSession != null) {
        _selectSession!.onSelectionEnd(current);
        _selectSession = null;
        return;
      }
      Polygon selection = Polygon.fromRect(
          Rect.fromPoints(current.startPosition, current.endPosition));
      CanvasHitTestResult result = CanvasHitTestResult();
      widget.controller._root
          .hitTestSelection(result, selection, widget.selectionBehavior);
      for (var entry in result.path) {
        entry.item.selected = true;
      }
    }
  }

  @override
  void startSelectSession(Offset position) {
    var newSession =
        CanvasSelectSession(startPosition: position, endPosition: position);
    widget.onSelectionStart?.call(newSession);
    widget.controller._root.visit(
      (item) {
        item.selected = false;
      },
    );
    if (widget.selectionHandler != null) {
      _selectSession = widget.selectionHandler!.onSelectionStart(newSession);
    }
    _selectNotifier.value = newSession;
  }

  @override
  void updateSelectSession(Offset delta) {
    var current = _selectNotifier.value;
    if (current != null) {
      widget.onSelectionChange?.call(current);
      var newSession =
          current.copyWith(endPosition: current.endPosition + delta);
      if (_selectSession != null) {
        _selectSession!.onSelectionChange(newSession, delta);
      }
      _selectNotifier.value = newSession;
    }
  }
}

class _CanvasItemBoundingBox extends StatefulWidget {
  final CanvasItem item;
  final CanvasItemNode node;
  final LayoutTransform? parentTransform;
  final void Function(CanvasItem item, bool hovered)? onHover;

  const _CanvasItemBoundingBox({
    required this.item,
    this.parentTransform,
    required this.node,
    this.onHover,
  });

  @override
  State<_CanvasItemBoundingBox> createState() => _CanvasItemBoundingBoxState();
}

class _CanvasItemBoundingBoxState extends State<_CanvasItemBoundingBox> {
  TransformSession? _session;
  Offset? _totalOffset;
  LayoutSnapping? _layoutSnapping;
  CanvasItemNode? _startItem;
  Layout? _startLayout;
  Offset? _startOffset;
  CanvasItem? _targetReparent;

  double get globalRotation {
    var rotation = widget.item.transform.rotation;
    if (widget.parentTransform != null) {
      rotation += widget.parentTransform!.rotation;
    }
    return rotation;
  }

  CanvasItemNode findSelected() {
    CanvasItemNode? current = widget.node;
    while (current != null) {
      var parent = current.parent;
      if (parent != null && !parent.item.selected) {
        break;
      }
      current = parent;
    }
    return current ?? widget.node;
  }

  double _computeRotation(CanvasItemNode? node) {
    double rotation = 0;
    while (node != null) {
      rotation += node.item.transform.rotation;
      node = node.parent;
    }
    return rotation;
  }

  @override
  Widget build(BuildContext context) {
    CanvasViewportData viewportData = CanvasViewportData.of(context);
    return ListenableBuilder(
      listenable: widget.item.transformListenable,
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
                    child: ListenableBuilder(
                      listenable: widget.item.selectedNotifier,
                      builder: (context, child) {
                        return MouseRegion(
                          cursor: widget.item.selected
                              ? SystemMouseCursors.move
                              : SystemMouseCursors.click,
                          onEnter: (event) {
                            if (widget.onHover != null) {
                              widget.onHover!(widget.item, true);
                            }
                          },
                          onExit: (event) {
                            if (widget.onHover != null) {
                              widget.onHover!(widget.item, false);
                            }
                          },
                          child: child,
                        );
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
                          _startItem = findSelected();
                          _startLayout = _startItem!.item.layout;
                          _totalOffset = Offset.zero;
                          _layoutSnapping = LayoutSnapping(
                              viewportData.snapping,
                              _startItem!.item,
                              _startItem!.parentTransform);
                          viewportData.fillInSnappingPoints(_layoutSnapping!);
                          _startOffset = details.localPosition;
                        },
                        onPanUpdate: (details) {
                          var item = _startItem!;
                          Offset delta = details.delta;
                          delta = rotatePoint(delta, globalRotation);
                          _totalOffset = _totalOffset! + delta;
                          Offset localDelta = _totalOffset!;
                          double rotation = _computeRotation(item.parent);
                          localDelta = rotatePoint(localDelta, -rotation);
                          item.item.layout = _startLayout!.drag(
                            localDelta,
                            snapping: _layoutSnapping,
                          );
                          _session!.visit(
                            (node) {
                              if (node.item == item.item) {
                                return;
                              }
                              Offset localDelta =
                                  _layoutSnapping?.newOffsetDelta ??
                                      _totalOffset!;
                              if (node.parentTransform != null) {
                                localDelta = rotatePoint(localDelta,
                                    -node.parentTransform!.rotation);
                              }
                              node.newLayout = node.layout
                                  .drag(localDelta, snapping: _layoutSnapping);
                            },
                          );
                          _session!.apply();
                          CanvasHitTestResult result = CanvasHitTestResult();
                          var position = _startOffset!;
                          position = widget.node.toGlobal(position);
                          viewportData.hitTest(result, position);
                          for (var i = result.path.length - 1; i >= 0; i--) {
                            var entry = result.path[i];
                            if (entry.item == item.item) {
                              continue;
                            }
                            if (item.item.isDescendantOf(entry.item)) {
                              continue;
                            }
                            _targetReparent = entry.item;
                            return;
                          }
                          // reparent to root
                          if (!viewportData.controller._root.children
                              .contains(item.item)) {
                            _targetReparent = viewportData.controller._root;
                            return;
                          }
                          _targetReparent = null;
                        },
                        onPanEnd: (details) {
                          _session = null;
                          _totalOffset = null;
                          _layoutSnapping = null;
                          _startLayout = null;
                          _startOffset = null;
                          var oldParent = widget.node.parent;
                          if (_targetReparent != null &&
                              oldParent?.item != _targetReparent) {
                            bool result = viewportData.onReparent?.call(
                                  ReparentDetails(
                                    item: widget.item,
                                    oldParent: oldParent?.item,
                                    newParent: _targetReparent,
                                  ),
                                ) ??
                                true;
                            if (result) {
                              // find same ancestor between old parent and new parent
                              if (oldParent != null) {
                                CanvasItemNode? current = oldParent;
                                Layout currentLayout = widget.item.layout;
                                while (current != null) {
                                  if (current.item
                                      .isDescendantOf(_targetReparent!)) {
                                    break;
                                  }
                                  var parent = current.parent;
                                  if (parent == null) {
                                    break;
                                  }
                                  currentLayout = currentLayout
                                      .transferToParent(current.item.layout);
                                  current = current.parent;
                                }
                                // current is the common ancestor
                                if (current != null) {
                                  current.visitTo(
                                    _targetReparent!,
                                    (item) {
                                      if (item == current!.item) {
                                        return;
                                      }
                                      currentLayout = currentLayout
                                          .transferToChild(item.layout);
                                    },
                                  );
                                }
                                widget.item.layout = currentLayout;
                                oldParent.item.removeChild(widget.item);
                              }
                              _targetReparent!.addChild(widget.item);
                            }
                          }
                        },
                        onPanCancel: () {
                          if (_session != null) {
                            _session!.reset();
                            _session = null;
                          }
                          _totalOffset = null;
                          _layoutSnapping = null;
                          _startLayout = null;
                          _startOffset = null;
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
                ),
                ListenableBuilder(
                  listenable: widget.item.childListenable,
                  builder: (context, child) {
                    return GroupWidget(
                      children: [
                        for (var child in widget.item.children)
                          _CanvasItemBoundingBox(
                            item: child,
                            parentTransform: widget.parentTransform == null
                                ? widget.item.transform
                                : widget.parentTransform! *
                                    widget.item.transform,
                            node: child.toNode(widget.node),
                            onHover: widget.onHover,
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
  final Widget? background;

  const CanvasItemWidget({
    super.key,
    this.parent,
    required this.item,
    this.background,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  @override
  Widget build(BuildContext context) {
    Widget? background = widget.item.build(context);
    Widget? secondaryBackground = widget.background;
    return ListenableBuilder(
        listenable: widget.item.transformListenable,
        builder: (context, child) {
          var layoutTransform = widget.item.transform;
          return Transform.translate(
            offset: layoutTransform.offset,
            child: Transform.rotate(
              angle: layoutTransform.rotation,
              alignment: Alignment.topLeft,
              child: GroupWidget(
                children: [
                  if (secondaryBackground != null) secondaryBackground,
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
                    listenable: widget.item.childListenable,
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
