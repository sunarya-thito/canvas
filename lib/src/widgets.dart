import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/helper_widget.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../canvas.dart';

class CanvasViewportThemeData {
  final Color backgroundColor;
  final Color isolationColor;
  final Decoration canvasDecoration;
  final Decoration selectionDecoration;

  const CanvasViewportThemeData({
    this.backgroundColor = const Color(0xFFB0B0B0),
    this.isolationColor = const Color(0x80FFFFFF),
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

  final ValueNotifier<Offset?> _cursorPosition = ValueNotifier(null);

  CanvasController({List<CanvasItem> children = const []}) {
    _root.children = children;
  }

  ValueListenable<Offset?> get cursorPositionListenable => _cursorPosition;
  Offset? get cursorPosition => _cursorPosition.value;

  void visit(void Function(CanvasItem item) visitor) {
    _root.visit(visitor);
  }

  void visitWithTransform(
      void Function(CanvasItem item, LayoutTransform? parentTransform) visitor,
      {bool rootSelectionOnly = false}) {
    _root.visitWithTransform(visitor, rootSelectionOnly: rootSelectionOnly);
  }

  void visitSnappingPoints(void Function(SnappingPoint snappingPoint) visitor) {
    _root.visitSnappingPoints(visitor);
  }

  void hitTestSelection(CanvasHitTestResult result, Polygon selection,
      {SelectionBehavior behavior = SelectionBehavior.intersect}) {
    _root.hitTestSelection(result, selection, behavior: behavior);
  }

  void hitTest(CanvasHitTestResult result, Offset position,
      {bool enableClipping = true}) {
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
    _root.childrenListenable.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _root.layoutListenable.removeListener(listener);
    _root.childrenListenable.removeListener(listener);
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
  ValueListenable<List<CanvasItem>> get childrenListenable =>
      _root.childrenListenable;

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

  void apply({LayoutSnapping? snapping}) {
    for (var node in nodes) {
      // if (node.newLayout != null && node.newLayout != node.layout) {
      //   node.item.layout = node.newLayout!;
      // }
      node.apply(node.layout, snapping: snapping);
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
  // Layout? newLayout;
  final LayoutChanges changes;

  TransformNode(this.item, this.transform, this.parentTransform, this.layout)
      : changes = layout.createChanges();

  void apply(Layout layout, {LayoutSnapping? snapping}) {
    if (snapping != null) {
      changes.snap(snapping);
    }
    changes.apply(layout);
    // if (newLayout != null && newLayout != item.layout) {
    //   item.layout = newLayout!;
    // }
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
  // TODO not everything belongs here, for example onReparenting and onReparentEnd
  // those should be in CanvasViewportHandle, and anything else that updates
  // quite frequently needs to be moved to CanvasViewportHandle and has its own
  // listenable.
  // TODO also add CanvasViewportHandle in here
  final CanvasController controller;
  final ResizeMode resizeMode;
  // final TransformControl transformControl;
  final bool multiSelect;
  final bool symmetricResize;
  final bool proportionalResize;
  final bool anchoredRotate;
  final SnappingConfiguration snapping;
  final CanvasViewportHandle handle;

  const CanvasViewportData({
    super.key,
    required this.controller,
    required this.handle,
    required this.multiSelect,
    required this.symmetricResize,
    required this.proportionalResize,
    required this.anchoredRotate,
    required this.resizeMode,
    required this.snapping,
    required super.child,
  });

  static CanvasViewportData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CanvasViewportData>()!;
  }

  @override
  bool updateShouldNotify(covariant CanvasViewportData oldWidget) {
    return oldWidget.controller != controller ||
        oldWidget.resizeMode != resizeMode ||
        oldWidget.multiSelect != multiSelect ||
        oldWidget.symmetricResize != symmetricResize ||
        oldWidget.proportionalResize != proportionalResize ||
        oldWidget.anchoredRotate != anchoredRotate ||
        oldWidget.snapping != snapping;
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
  final CanvasViewportThemeData theme;
  final double scrollSpeed;
  final EdgeInsets dragPadding;

  const CanvasViewport({
    super.key,
    required this.controller,
    this.minZoom = 0.1,
    this.maxZoom = 5,
    this.scrollSpeed = 0.01,
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
    this.theme = const CanvasViewportThemeData(),
    this.dragPadding = const EdgeInsets.all(64),
  });

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _ImmutableSetNotifier<T> extends ValueNotifier<Set<T>> {
  _ImmutableSetNotifier(Set<T> value) : super(value);

  void _notify() {
    notifyListeners();
  }
}

class _CanvasViewportState extends State<CanvasViewport>
    with CanvasViewportHandle, SingleTickerProviderStateMixin {
  /// to preserve state and to prevent unnecessary rebuilds
  final GlobalKey _viewportKey = GlobalKey();
  // CanvasItem? _hoveredItem;
  late Offset _canvasOffset;
  late Size _size;
  late Ticker _ticker;
  late Duration _lastTime;
  final Set<CanvasElementDragger> _tickerTicket = {};

  late ValueNotifier<CanvasTransform> _transformNotifier;
  final ValueNotifier<CanvasItem?> _hoveredItemNotifier = ValueNotifier(null);
  final ValueNotifier<CanvasItem?> _reparentTargetNotifier =
      ValueNotifier(null);
  final ValueNotifier<CanvasItem?> _focusedItemNotifier = ValueNotifier(null);
  final ValueNotifier<Offset?> _cursorPositionNotifier = ValueNotifier(null);
  Offset? _localCursor;

  Offset? _totalSelectionDelta;

  final ValueNotifier<CanvasSelectSession?> _selectNotifier =
      ValueNotifier(null);
  CanvasSelectionSession? _selectSession;

  @override
  CanvasHitTestResult hitTestAtCursor() {
    CanvasHitTestResult result = CanvasHitTestResult();
    var cursor = _cursorPositionNotifier.value;
    if (cursor != null) {
      controller.hitTest(result, cursor);
    }
    return result;
  }

  @override
  void markFocused(CanvasItem node) {
    _focusedItemNotifier.value = node;
  }

  @override
  CanvasViewportThemeData get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _transformNotifier = ValueNotifier(widget.initialTransform);
    _cursorPositionNotifier.addListener(_handleCursorPositionUpdate);
    _ticker = createTicker(_handleTicker);
  }

  void _handleCursorPositionUpdate() {
    widget.controller._cursorPosition.value = _cursorPositionNotifier.value;
  }

  @override
  void didUpdateWidget(covariant CanvasViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (symmetricResize != oldWidget.symmetricResize ||
        proportionalResize != oldWidget.proportionalResize) {
      var current = _selectNotifier.value;
      if (_selectSession != null && current != null) {
        _selectSession!.onSelectionChange(current, _totalSelectionDelta!);
      }
    }
    if (widget.controller != oldWidget.controller) {
      _handleCursorPositionUpdate();
    }
  }

  @override
  bool get symmetricResize => widget.symmetricResize;

  @override
  bool get proportionalResize => widget.proportionalResize;

  @override
  Size get size => _size;

  @override
  bool get enableInstantSelection => widget.selectionHandler != null;

  @override
  void instantSelection(Offset position) {
    if (widget.selectionHandler != null) {
      widget.selectionHandler!.onInstantSelection(this, position);
    }
  }

  @override
  void drag(Offset delta) {
    setState(() {
      transform = CanvasTransform(
        offset: transform.offset + delta,
        zoom: transform.zoom,
      );
    });
  }

  @override
  void zoomAt(Offset position, double delta) {
    delta = delta * transform.zoom;
    position = position - widget.alignment.alongSize(widget.canvasSize);
    var currentZoom = transform.zoom;
    if (currentZoom + delta < widget.minZoom) {
      delta = widget.minZoom - currentZoom;
    }
    if (currentZoom + delta > widget.maxZoom) {
      delta = widget.maxZoom - currentZoom;
    }
    setState(() {
      transform = CanvasTransform(
        offset: transform.offset - position * delta,
        zoom: currentZoom + delta,
      );
    });
  }

  @override
  Offset get canvasOffset => _canvasOffset;

  @override
  CanvasTransform get transform => _transformNotifier.value;

  @override
  set transform(CanvasTransform value) {
    _transformNotifier.value = value;
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

  Offset _localToViewport(Offset local, Size size) {
    var transform = this.transform;
    var alignmentOffset = widget.alignment.alongSize(size);
    var canvasOffset = widget.alignment.alongSize(widget.canvasSize);
    Offset totalOffset =
        alignmentOffset + transform.offset - canvasOffset * transform.zoom;
    return (local - totalOffset) / transform.zoom;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    var canvasOffset = widget.alignment.alongSize(widget.canvasSize);
    return ListenableBuilder(
        listenable: _transformNotifier,
        builder: (context, child) {
          return ColoredBox(
            color: theme.backgroundColor,
            child: LayoutBuilder(builder: (context, constraints) {
              var offset = widget.alignment.alongSize(constraints.biggest);
              var transform = this.transform;
              _canvasOffset =
                  offset + transform.offset - canvasOffset * transform.zoom;
              _size = constraints.biggest;
              return Listener(
                onPointerMove: (event) {
                  _localCursor = event.localPosition;
                  _cursorPositionNotifier.value =
                      _localToViewport(event.localPosition, _size);
                },
                child: MouseRegion(
                  onEnter: (event) {
                    _cursorPositionNotifier.value =
                        _localToViewport(event.localPosition, _size);
                    _localCursor = event.localPosition;
                  },
                  onExit: (event) {
                    _cursorPositionNotifier.value = null;
                    _localCursor = null;
                  },
                  onHover: (event) {
                    _cursorPositionNotifier.value =
                        _localToViewport(event.localPosition, _size);
                    _localCursor = event.localPosition;
                  },
                  child: GestureDetector(
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
                              controller: widget.controller,
                              resizeMode: widget.resizeMode,
                              multiSelect: widget.multiSelect,
                              symmetricResize: widget.symmetricResize,
                              proportionalResize: widget.proportionalResize,
                              anchoredRotate: widget.anchoredRotate,
                              snapping: widget.snapping,
                              handle: this,
                              child: Transform.translate(
                                offset: offset +
                                    transform.offset -
                                    canvasOffset * transform.zoom,
                                child: GroupWidget(
                                  children: [
                                    Transform.scale(
                                      alignment: Alignment.topLeft,
                                      scale: transform.zoom,
                                      child: CanvasItemWidget(
                                        background: widget.canvasSize.isEmpty
                                            ? null
                                            : Container(
                                                width: widget.canvasSize.width,
                                                height:
                                                    widget.canvasSize.height,
                                                decoration:
                                                    theme.canvasDecoration,
                                              ),
                                        item: widget.controller._root,
                                        onHover: (item, hovered) {
                                          if (hovered) {
                                            // if (_hoveredItem != item) {
                                            //   setState(() {
                                            //     _hoveredItem = item;
                                            //   });
                                            // }
                                            _hoveredItemNotifier.value = item;
                                          } else {
                                            // if (_hoveredItem == item) {
                                            //   setState(() {
                                            //     _hoveredItem = null;
                                            //   });
                                            // }
                                            if (_hoveredItemNotifier.value ==
                                                item) {
                                              _hoveredItemNotifier.value = null;
                                            }
                                          }
                                        },
                                        handle: this,
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
                                              session.startPosition *
                                                  transform.zoom,
                                              session.endPosition *
                                                  transform.zoom);
                                          return Transform.translate(
                                            offset: rect.topLeft,
                                            child: Container(
                                              width: rect.width,
                                              height: rect.height,
                                              decoration:
                                                  theme.selectionDecoration,
                                            ),
                                          );
                                        },
                                      ),
                                    // IgnorePointer(
                                    //   child: Transform.scale(
                                    //     scale: transform.zoom,
                                    //     alignment: Alignment.topLeft,
                                    //     child: ListenableBuilder(
                                    //       listenable: Listenable.merge({
                                    //         _reparentTargetNotifier,
                                    //       }),
                                    //       builder: (context, child) {
                                    //         var focusedChildren =
                                    //             _focusedItemsNotifier.value.map(
                                    //           (e) => e.childrenListenable,
                                    //         );
                                    //         return ListenableBuilder(
                                    //           listenable: Listenable.merge(
                                    //             focusedChildren,
                                    //           ),
                                    //           builder: (context, child) {
                                    //             return ListenableBuilder(
                                    //               listenable: Listenable.merge(
                                    //                 focusedChildren
                                    //                     .expand((element) =>
                                    //                         element.value)
                                    //                     .map((e) =>
                                    //                         e.contentFocusedNotifier),
                                    //               ),
                                    //               builder: (context, child) {
                                    //                 var reparentTarget =
                                    //                     _reparentTargetNotifier.value;
                                    //                 Iterable<CanvasItem>
                                    //                     selectedItems =
                                    //                     _focusedItemsNotifier.value
                                    //                         .where(
                                    //                   (e) {
                                    //                     return e.children
                                    //                             .isNotEmpty &&
                                    //                         !e.children.any(
                                    //                             (element) => element
                                    //                                 .contentFocused);
                                    //                   },
                                    //                 );
                                    //                 if (reparentTarget == null &&
                                    //                     selectedItems.isEmpty) {
                                    //                   return const SizedBox();
                                    //                 }
                                    //                 if (reparentTarget != null &&
                                    //                     !reparentTarget.opaque &&
                                    //                     selectedItems.isEmpty) {
                                    //                   return const SizedBox();
                                    //                 }
                                    //                 return CustomPaint(
                                    //                   painter: IsolationPainter(
                                    //                     holes: IsolationPainter
                                    //                         .createBounds([
                                    //                       if (reparentTarget != null)
                                    //                         reparentTarget,
                                    //                       ...selectedItems,
                                    //                     ]),
                                    //                     color: theme.isolationColor,
                                    //                   ),
                                    //                 );
                                    //               },
                                    //             );
                                    //           },
                                    //         );
                                    //       },
                                    //     ),
                                    //   ),
                                    // ),
                                    widget.transformControl.build(
                                        context, widget.controller._root, false)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_shouldCancelObjectDragging)
                            Positioned.fill(
                              child: widget.gestures.wrapViewport(
                                  context, const SizedBox(), this),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        });
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
    _totalSelectionDelta = null;
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
      widget.controller.hitTestSelection(result, selection,
          behavior: widget.selectionBehavior);
      if (widget.multiSelect) {
        for (var entry in result.path) {
          entry.item.selected = true;
        }
      } else {
        controller.visit(
          (item) {
            item.selected = result.path.any((entry) => entry.item == item);
          },
        );
      }
    }
  }

  @override
  void startSelectSession(Offset position) {
    _totalSelectionDelta = Offset.zero;
    position = position / transform.zoom;
    var newSession =
        CanvasSelectSession(startPosition: position, endPosition: position);
    widget.onSelectionStart?.call(newSession);
    if (widget.selectionHandler != null) {
      widget.controller._root.visit(
        (item) {
          item.selected = false;
        },
      );
      _selectSession =
          widget.selectionHandler!.onSelectionStart(this, newSession);
    }
    _selectNotifier.value = newSession;
  }

  @override
  void updateSelectSession(Offset delta) {
    if (_totalSelectionDelta == null) {
      return;
    }
    _totalSelectionDelta = _totalSelectionDelta! + delta;
    var current = _selectNotifier.value;
    if (current != null) {
      widget.onSelectionChange?.call(current);
      var viewportZoom = transform.zoom;
      var newSession = current.copyWith(
          endPosition: current.endPosition + delta / viewportZoom);
      if (_selectSession != null) {
        _selectSession!.onSelectionChange(
            newSession, _totalSelectionDelta! / viewportZoom);
      }
      _selectNotifier.value = newSession;
    }
  }

  @override
  SnappingConfiguration get snappingConfiguration => widget.snapping;

  @override
  CanvasController get controller => widget.controller;

  @override
  LayoutSnapping createLayoutSnapping(CanvasItem item,
      [bool fillInSnappingPoints = true]) {
    LayoutSnapping snapping = LayoutSnapping(
      snappingConfiguration,
      item,
      item.parentTransform,
    );
    if (fillInSnappingPoints) {
      controller.visitSnappingPoints(
        (snappingPoint) {
          snapping.snappingPoints.add(snappingPoint);
        },
      );
    }
    return snapping;
  }

  @override
  ValueListenable<CanvasItem?> get reparentTargetListenable =>
      _reparentTargetNotifier;

  @override
  void endDraggingSession(CanvasElementDragger owner) {
    if (_tickerTicket.remove(owner)) {
      _checkTicker();
    }
  }

  @override
  void startDraggingSession(CanvasElementDragger owner) {
    if (_tickerTicket.add(owner)) {
      _checkTicker();
    }
  }

  void _checkTicker() {
    if (_tickerTicket.isEmpty) {
      if (_ticker.isActive) {
        _ticker.stop();
      }
    } else {
      if (!_ticker.isActive) {
        _lastTime = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _handleTicker(Duration elapsed) {
    var delta = elapsed - _lastTime;
    var cursor = _localCursor;
    if (cursor == null) return;
    var dragPadding = widget.dragPadding;
    double topDiff = cursor.dy - dragPadding.top;
    double bottomDiff = _size.height - cursor.dy - dragPadding.bottom;
    double leftDiff = cursor.dx - dragPadding.left;
    double rightDiff = _size.width - cursor.dx - dragPadding.right;
    if (topDiff > 0 && leftDiff > 0 && bottomDiff > 0 && rightDiff > 0) {
      return;
    }
    double dxScroll = 0;
    double dyScroll = 0;
    double speed = (widget.scrollSpeed / 1000) * delta.inMilliseconds;
    if (topDiff <= 0) {
      dyScroll = -topDiff * speed;
    } else if (bottomDiff <= 0) {
      dyScroll = bottomDiff * speed;
    }
    if (leftDiff <= 0) {
      dxScroll = -leftDiff * speed;
    } else if (rightDiff <= 0) {
      dxScroll = rightDiff * speed;
    }
    if (dxScroll != 0 || dyScroll != 0) {
      for (var dragger in _tickerTicket) {
        dragger.handleDragAdjustment(Offset(dxScroll, dyScroll));
      }
    }
  }

  @override
  bool canReparent(CanvasItem item, CanvasItem target) {
    assert(item.parent != null, 'Item must be attached to a viewport');
    return widget.onReparent?.call(ReparentDetails(
            item: item, oldParent: item.parent!, newParent: target)) ??
        true;
  }

  @override
  CanvasItem? get focusedItem => _focusedItemNotifier.value;

  @override
  ValueListenable<CanvasItem?> get focusedItemListenable =>
      _focusedItemNotifier;

  @override
  void handleReparenting(CanvasItem? target) {
    _reparentTargetNotifier.value = target;
  }

  @override
  CanvasItem? get hoveredItem => _hoveredItemNotifier.value;

  @override
  ValueListenable<CanvasItem?> get hoveredItemListenable =>
      _hoveredItemNotifier;

  @override
  ValueListenable<CanvasTransform> get transformListenable =>
      _transformNotifier;
}

class _CanvasItemBoundingBox extends StatefulWidget {
  final CanvasItem item;
  final LayoutTransform? parentTransform;
  final void Function(CanvasItem item, bool hovered)? onHover;
  final Widget? child;

  const _CanvasItemBoundingBox({
    this.parentTransform,
    required this.item,
    this.onHover,
    this.child,
  });

  @override
  State<_CanvasItemBoundingBox> createState() => _CanvasItemBoundingBoxState();
}

class _CanvasItemBoundingBoxState extends State<_CanvasItemBoundingBox>
    with CanvasElementDragger {
  TransformSession? _session;
  Offset? _totalOffset;
  LayoutSnapping? _layoutSnapping;
  CanvasItem? _startItem;
  Layout? _startLayout;
  CanvasItem? _targetReparent;
  CanvasViewportData? _viewportData;
  VoidCallback? _onUpdate;

  @override
  void handleDragAdjustment(Offset delta) {
    if (_totalOffset != null && _onUpdate != null) {
      _totalOffset = _totalOffset! - delta / viewportData.handle.transform.zoom;
      _onUpdate!();
      viewportData.handle.drag(delta);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewportData = CanvasViewportData.of(context);
  }

  CanvasViewportData get viewportData {
    return _viewportData!;
  }

  double get globalRotation {
    var rotation = widget.item.transform.rotation;
    if (widget.parentTransform != null) {
      rotation += widget.parentTransform!.rotation;
    }
    return rotation;
  }

  CanvasItem findSelected() {
    CanvasItem? current = widget.item;
    while (current != null) {
      var parent = current.parent;
      if (parent != null && !parent.selected) {
        break;
      }
      current = parent;
    }
    return current ?? widget.item;
  }

  double _computeRotation(CanvasItem? node) {
    double rotation = 0;
    while (node != null) {
      rotation += node.transform.rotation;
      node = node.parent;
    }
    return rotation;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge({
        widget.item.parentListenable,
        viewportData.handle.focusedItemListenable,
      }),
      builder: (context, child) {
        var parent = widget.item.parent;
        return IgnorePointer(
          // ignoring: !parentFocused,
          // TODO: fix this
          ignoring: false,
          child: ListenableBuilder(
            listenable: widget.item.selectedNotifier,
            builder: (context, child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                // onTap: parentFocused
                // TODO: fix this
                onTap: true
                    ? () {
                        if (viewportData.multiSelect) {
                          widget.item.selected = !widget.item.selected;
                        } else if (!widget.item.selected) {
                          viewportData.handle.visit(
                            (item) {
                              item.selected = item == widget.item;
                            },
                          );
                        } else {
                          // widget.item.contentFocused = widget.item.hasContent;
                          // TODO: fix this
                        }
                      }
                    : null,
                child: MouseRegion(
                  // opaque: parentFocused,
                  // cursor: contentFocused
                  // TODO: fix this
                  cursor: true
                      ? MouseCursor.defer
                      : widget.item.selected
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
                ),
              );
            },
            child: PanGesture(
              // enable: parentFocused && !contentFocused,
              onPanStart: (details) {
                viewportData.handle.startDraggingSession(this);
                if (!widget.item.selected) {
                  if (viewportData.multiSelect) {
                    widget.item.selected = !widget.item.selected;
                  } else {
                    viewportData.handle.visit(
                      (item) {
                        item.selected = item == widget.item;
                      },
                    );
                  }
                }
                _session =
                    viewportData.handle.beginTransform(rootSelectionOnly: true);
                _startItem = findSelected();
                _startLayout = _startItem!.layout;
                _totalOffset = Offset.zero;
                _layoutSnapping = LayoutSnapping(viewportData.snapping,
                    _startItem!, _startItem!.parentTransform);
                viewportData.handle.fillInSnappingPoints(_layoutSnapping!);
              },
              onPanUpdate: (details) {
                Offset flip;
                var size = widget.item.transform.size;
                if (size.width < 0 && size.height < 0) {
                  flip = const Offset(-1, -1);
                } else if (size.width < 0) {
                  flip = const Offset(-1, 1);
                } else if (size.height < 0) {
                  flip = const Offset(1, -1);
                } else {
                  flip = const Offset(1, 1);
                }
                var item = _startItem!;
                Offset delta = details.delta
                    .multiply(widget.item.transform.scale)
                    .multiply(flip);
                delta = rotatePoint(delta, globalRotation);
                _totalOffset = _totalOffset! + delta;
                void update() {
                  Offset localDelta = _totalOffset!;
                  double rotation = _computeRotation(item.parent);
                  localDelta = rotatePoint(localDelta, -rotation);
                  item.layout = _startLayout!.drag(
                    localDelta,
                    snapping: _layoutSnapping,
                  );
                  _session!.visit(
                    (node) {
                      if (node.item == item) {
                        return;
                      }
                      Offset localDelta =
                          _layoutSnapping?.newOffsetDelta ?? _totalOffset!;
                      if (node.parentTransform != null) {
                        localDelta = rotatePoint(
                            localDelta, -node.parentTransform!.rotation);
                      }
                      node.changes.drag(localDelta);
                      // node.newLayout = node.layout
                      //     .drag(localDelta, snapping: _layoutSnapping);
                    },
                  );
                  _session!.apply();
                  CanvasHitTestResult hitTestResult =
                      viewportData.handle.hitTestAtCursor();
                  CanvasItem targetReparent =
                      findReparentTarget(item, hitTestResult) ??
                          viewportData.controller._root;
                  if (targetReparent != _targetReparent) {
                    _targetReparent = targetReparent;
                    viewportData.handle.handleReparenting(targetReparent);
                  }
                }

                _onUpdate = update;
                update();
              },
              onPanEnd: (details) {
                var item = _startItem!;
                var targetReparent = _targetReparent;
                viewportData.handle.endDraggingSession(this);
                _session = null;
                _onUpdate = null;
                _totalOffset = null;
                _layoutSnapping = null;
                _startLayout = null;
                _startItem = null;
                _targetReparent = null;
                var oldParent = widget.item.parent;
                viewportData.handle.handleReparenting(null);
                if (targetReparent != null && oldParent != targetReparent) {
                  bool result = viewportData.handle
                      .canReparent(widget.item, targetReparent);
                  if (result) {
                    reparent(item, targetReparent);
                    return;
                  }
                }
              },
              onPanCancel: () {
                viewportData.handle.endDraggingSession(this);
                if (_session != null) {
                  _session!.reset();
                  _session = null;
                }
                _onUpdate = null;
                _totalOffset = null;
                _layoutSnapping = null;
                _startLayout = null;
                _targetReparent = null;
                _startItem = null;
                viewportData.handle.handleReparenting(null);
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class CanvasItemWidget extends StatefulWidget {
  final CanvasItem item;
  final Widget? background;
  final void Function(CanvasItem item, bool hovered)? onHover;
  final LayoutTransform? parentTransform;
  final CanvasViewportHandle handle;

  const CanvasItemWidget({
    super.key,
    required this.item,
    this.background,
    this.onHover,
    this.parentTransform,
    required this.handle,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  Widget? buildChild(BuildContext context) {
    var background = widget.item.build(context);
    if (widget.item.opaque) {
      var layoutTransform = widget.item.transform;
      return Transform.scale(
        scaleX: layoutTransform.scale.dx,
        scaleY: layoutTransform.scale.dy,
        alignment: Alignment.topLeft,
        child: Box(
          size: layoutTransform.size,
          child: _CanvasItemBoundingBox(
            item: widget.item,
            onHover: widget.onHover,
            parentTransform: widget.parentTransform,
            child: background == null
                ? null
                : ListenableBuilder(
                    // listenable: widget.item.contentFocusedNotifier,
                    // TODO: Fix this
                    listenable: Listenable.merge([]),
                    builder: (context, child) {
                      return IgnorePointer(
                        // ignoring: !widget.item.contentFocused,
                        // TODO: Fix this
                        ignoring: false,
                        child: background,
                      );
                    }),
          ),
        ),
      );
    }
    return background;
  }

  @override
  Widget build(BuildContext context) {
    Widget? secondaryBackground = widget.background;
    return ListenableBuilder(
        listenable: Listenable.merge({
          widget.item.transformListenable,
          widget.item.selectedNotifier,
          widget.item.childrenListenable,
          widget.handle.reparentTargetListenable,
          // widget.item.contentFocusedNotifier,
        }),
        builder: (context, child) {
          var layoutTransform = widget.item.transform;
          var scaledSize = layoutTransform.scaledSize;
          Widget? backgroundChild = buildChild(context);
          return Transform.translate(
            offset: layoutTransform.offset,
            child: Transform.rotate(
              angle: layoutTransform.rotation,
              alignment: Alignment.topLeft,
              child: GroupWidget(
                size: widget.item.clipContent && widget.item.opaque
                    // TODO: Fix this
                    // widget.item.opaque &&
                    // !widget.item.contentFocused
                    ? scaledSize
                    : null,
                clipBehavior: widget.item.clipContent && widget.item.opaque
                    // TODO: Fix this
                    // widget.item.opaque &&
                    // !widget.item.contentFocused
                    ? Clip.hardEdge
                    : Clip.none,
                children: [
                  if (secondaryBackground != null) secondaryBackground,
                  if (backgroundChild != null) backgroundChild,
                  GroupWidget(
                    children: widget.item.children.map((child) {
                      return CanvasItemWidget(
                        handle: widget.handle,
                        item: child,
                        parentTransform: widget.parentTransform == null
                            ? layoutTransform
                            : widget.parentTransform! * layoutTransform,
                        onHover: widget.onHover,
                      );
                    }).toList(),
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

  Offset toOffset() {
    return Offset(width, height);
  }
}
