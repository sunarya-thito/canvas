import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/actions.dart';
import 'package:canvas/src/editor/control.dart';
import 'package:canvas/src/editor/debug.dart';
import 'package:canvas/src/editor/grid.dart';
import 'package:canvas/src/editor/ruler.dart';
import 'package:canvas/src/editor/snap.dart';
import 'package:canvas/src/external/widgets.dart';
import 'package:canvas/src/editor/scrollable.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:canvas/src/selection/widgets.dart';
import 'package:data_widget/data_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:flutter/src/gestures/hit_test.dart';
import 'package:flutter/widgets.dart';

class CanvasEditor extends StatefulWidget {
  final CanvasEditorController controller;
  final EditorDragGesture gesture;
  final CanvasRoot root;
  final TextDirection textDirection;
  final CanvasSelectionMode selectionMode;
  final FocusNode? focusNode;
  final bool scrollAsZoom;
  final bool showRuler;
  final SnappingConfiguration snappingConfiguration;
  final Offset minOffset;
  final Offset maxOffset;
  final double minZoom;
  final double maxZoom;

  const CanvasEditor({
    super.key,
    required this.controller,
    this.gesture = const EditorSelectDragGesture(),
    required this.root,
    this.textDirection = TextDirection.ltr,
    this.selectionMode = CanvasSelectionMode.single,
    this.focusNode,
    this.scrollAsZoom = true,
    this.showRuler = true,
    this.snappingConfiguration = const SnappingConfiguration(),
    this.minOffset = const Offset(-10000, -10000),
    this.maxOffset = const Offset(10000, 10000),
    this.minZoom = 0.01,
    this.maxZoom = 100,
  });

  @override
  State<CanvasEditor> createState() => CanvasEditorState();
}

class CanvasEditorState extends State<CanvasEditor>
    with TickerProviderStateMixin, CanvasEditorHandler {
  static const rootConstraints = BoxConstraints.tightFor(height: 0, width: 0);
  late CanvasRoot _root;
  late CanvasRootState _rootState;
  late FocusNode _focusNode;
  late Size _editorSize;

  final GlobalKey _viewportKey = GlobalKey();

  Ticker? _dragTicker;
  Offset? _dragShift;
  Duration? _lastDragTick;

  Offset? _dragStart;
  final MutableNotifier<List<CanvasRulerSnappingPoint>> _rulerSnappingPoints =
      MutableNotifier([]);
  final ValueNotifier<CanvasRulerSnappingPoint?> _selectedRulerSnappingPoint =
      ValueNotifier(null);

  EditorControlSession? _controlSession;

  @override
  EditorControlSession? get controlSession => _controlSession;

  @override
  CanvasRootState get rootState => _rootState;

  void _handleDrag(Offset position) {
    // position is local to the editor widget
    double shiftX = 0;
    double shiftY = 0;

    EdgeInsets shiftPadding = EdgeInsets.all(20);

    double verticalMin = shiftPadding.top;
    double verticalMax = viewportSize.height - shiftPadding.bottom;
    double horizontalMin = shiftPadding.left;
    double horizontalMax = viewportSize.width - shiftPadding.right;

    if (position.dy < verticalMin) {
      shiftY = -(verticalMin - position.dy) / shiftPadding.top;
    } else if (position.dy > verticalMax) {
      shiftY = (position.dy - verticalMax) / shiftPadding.bottom;
    }

    if (position.dx < horizontalMin) {
      shiftX = -(horizontalMin - position.dx) / shiftPadding.left;
    } else if (position.dx > horizontalMax) {
      shiftX = (position.dx - horizontalMax) / shiftPadding.right;
    }
    if (shiftX != 0 || shiftY != 0) {
      _dragShift = Offset(-shiftX, -shiftY);
      _startDragShift();
    } else {
      _stopDragTicker();
    }
  }

  void _startDragShift() {
    if (_dragTicker?.isActive == true) {
      return;
    }
    _lastDragTick = null;
    _dragTicker?.stop();
    _dragTicker = createTicker(_onDragTick);
    _dragTicker?.start();
  }

  void _onDragTick(Duration elapsed) {
    Duration delta = elapsed - (_lastDragTick ?? Duration.zero);
    var shift = _dragShift;
    if (shift != null) {
      shift = Offset(shift.dx * delta.inMilliseconds / 2,
          shift.dy * delta.inMilliseconds / 2);
      shiftViewport(shift);
      var controlSession = _controlSession;
      if (controlSession != null) {
        controlSession.shift(-shift / transform.zoom);
        controlSession.onUpdate();
      }
    }
    _lastDragTick = elapsed;
  }

  void _stopDragTicker() {
    _dragTicker?.stop();
    _dragTicker = null;
  }

  @override
  void sendNotification(Notification notification) {
    notification.dispatch(context);
  }

  @override
  T startControlSession<T extends EditorControlSession>(
      T session, Offset globalStart) {
    if (_controlSession != null) {
      cancelControlSession(_controlSession!);
    }
    var renderBox =
        _viewportKey.currentContext!.findRenderObject() as RenderBox;
    globalStart = renderBox.globalToLocal(globalStart);
    globalStart = transformOffset(globalStart, getGlobalToLocalTransform());
    session.start(globalStart);
    _controlSession = session;
    return session;
  }

  @override
  T? updateControlSession<T extends EditorControlSession>(
      T session, Offset globalEnd) {
    if (_controlSession != session) {
      return null;
    }
    var renderBox =
        _viewportKey.currentContext!.findRenderObject() as RenderBox;
    globalEnd = renderBox.globalToLocal(globalEnd);
    _handleDrag(globalEnd);
    globalEnd = transformOffset(globalEnd, getGlobalToLocalTransform());
    session.update(globalEnd);
    if (!snappingConfiguration.enableSnapping) {
      session.onUpdate();
      return session;
    }
    var snappingResult = snap(session.visitTransformedSnappingPoint);
    if (snappingResult != null) {
      globalEnd = snappingResult.newOffset;
      session.update(globalEnd);
    }
    session.onUpdate();
    return session;
  }

  @override
  void endControlSession(EditorControlSession session) {
    if (_controlSession == session) {
      _controlSession = null;
      session.onApply();
    }
    _stopDragTicker();
  }

  @override
  void cancelControlSession(EditorControlSession session) {
    if (_controlSession == session) {
      _controlSession = null;
      session.onCancel();
    }
    _stopDragTicker();
  }

  // @override
  // SnappingResult? snap(SnappingPoint point) {
  //   SnappingResult? result;
  //   visitSnappingPoint(
  //     (other) {
  //       result = point.computeSnapping(this, other, snappingConfiguration);
  //       if (result != null) {
  //         return false;
  //       }
  //       return true;
  //     },
  //   );
  //   return result;
  // }

  @override
  SnappingResult? snap(SnappingPointHost host) {
    SnappingResult? result;
    host(
      (point) {
        visitSnappingPoint(
          (other) {
            result = point.computeSnapping(this, other, snappingConfiguration);
            return result == null;
          },
        );
        return result == null;
      },
    );
    return result;
  }

  @override
  void dragViewport(Offset delta) {
    var newOffset = widget.controller.value.offset + delta;
    double clampedDx = newOffset.dx.clamp(
      widget.minOffset.dx,
      widget.maxOffset.dx,
    );
    double clampedDy = newOffset.dy.clamp(
      widget.minOffset.dy,
      widget.maxOffset.dy,
    );
    widget.controller.value = widget.controller.value.copyWith(
      offset: Offset(clampedDx, clampedDy),
    );
    if (_dragStart != null) {
      _dragStart = _dragStart! + delta;
    }
  }

  @override
  void zoomAtViewport(Offset at, double delta) {
    if (delta > 0) {
      var newZoom = transform.zoom + delta;
      if (newZoom > widget.maxZoom) {
        return;
      }
    } else if (delta < 0) {
      var newZoom = transform.zoom + delta;
      if (newZoom < widget.minZoom) {
        return;
      }
    } else {
      return;
    }
    transform = transform.zoomAt(at, delta: delta);
  }

  @override
  Size get viewportSize => _editorSize;

  @override
  SnappingConfiguration get snappingConfiguration =>
      widget.snappingConfiguration;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _root = widget.root;
    _rootState = _root.createState(editor: this);
    _root.attach(_rootState);
    _performFullLayout();
    _rootState.addListener(_performFullLayout);
  }

  void _performFullLayout() {
    _rootState.layout(rootConstraints, widget.textDirection);
  }

  @override
  ValueListenable<CanvasRulerSnappingPoint?>
      get selectedSnappingPointListenable =>
          ValueNotifierUnmodifiableView(_selectedRulerSnappingPoint);

  @override
  set selectedSnappingPoint(CanvasRulerSnappingPoint? point) {
    _selectedRulerSnappingPoint.value = point;
  }

  @override
  Rect computeViewportBounds() {
    Matrix4 transform = getLocalToGlobalTransform();
    Rect rootBounds =
        _rootState.computeViewportBounds(parentTransform: transform);
    return rootBounds;
  }

  @override
  bool visitSnappingPoint(SnappingPointVisitor visitor) {
    return _rootState.visitSnappingPoint(visitor);
  }

  @override
  CanvasRulerSnappingPoint createRulerSnappingPoint(
      double offset, Axis direction) {
    CanvasRulerSnappingPoint point =
        CanvasRulerSnappingPoint(offset: offset, axis: direction);
    _rulerSnappingPoints.mutate(
      (value) {
        value.add(point);
      },
    );
    return point;
  }

  @override
  void removeRulerSnappingPoint(CanvasRulerSnappingPoint point) {
    _rulerSnappingPoints.mutate(
      (value) {
        value.remove(point);
      },
    );
    if (selectedSnappingPoint == point) {
      selectedSnappingPoint = null;
    }
  }

  @override
  void didUpdateWidget(covariant CanvasEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root) {
      _rootState.removeListener(_performFullLayout);
      _root.detach(_rootState);
      _root = widget.root;
      _rootState = _root.createState(editor: this);
      _root.attach(_rootState);
      _performFullLayout();
      _rootState.addListener(_performFullLayout);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _rootState.removeListener(_performFullLayout);
    _root.detach(_rootState);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void onPointerScroll(PointerScrollEvent event, CanvasEditorHandler editor) {
    var zoomDelta = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
    zoomAtViewport(event.localPosition, zoomDelta);
  }

  @override
  Selection? getSelectionForItem(CanvasItemState item) {
    for (var selection in _selections) {
      if (selection.contains(item)) {
        return selection;
      }
    }
    return null;
  }

  @override
  void handleItemClick(CanvasItemState targetClick) {
    if (targetClick == _rootState) {
      if (widget.selectionMode != CanvasSelectionMode.multiple) {
        localSelection = null;
      }
      return;
    }
    if (widget.selectionMode != CanvasSelectionMode.multiple) {
      localSelection = null;
    }
    switch (widget.selectionMode) {
      case CanvasSelectionMode.single:
        setToLocalSelection(targetClick);
        break;
      case CanvasSelectionMode.multiple:
        addToLocalSelection(targetClick);
        break;
      case CanvasSelectionMode.none:
        break;
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    assert(_rootState.hasSize, 'Root object has not been laid out');
    return Actions(
      actions: {
        CanvasUpdateLayoutDataIntent: Action.overridable(
          defaultAction: CanvasUpdateLayoutDataAction(),
          context: context,
        ),
        CanvasUpdateChildrenIntent: Action.overridable(
          defaultAction: CanvasUpdateChildrenAction(),
          context: context,
        ),
        CanvasRemoveRulerSnappingPointIntent: Action.overridable(
          defaultAction: CanvasRemoveRulerSnappingPointAction(),
          context: context,
        ),
        CanvasCreateRulerSnappingPointIntent: Action.overridable(
          defaultAction: CanvasCreateRulerSnappingPointAction(),
          context: context,
        ),
      },
      child: ListenableBuilder(
        listenable: _rulerSnappingPoints,
        builder: (context, child) {
          return CanvasRuler(
            controller: widget.controller,
            editor: this,
            showRuler: widget.showRuler,
            snappingPoints: _rulerSnappingPoints.value,
            child: child!,
          );
        },
        child: LayoutBuilder(builder: (context, constraints) {
          _editorSize = constraints.biggest;
          return Focus(
            focusNode: _focusNode,
            child: CanvasEditorScrollable(
              controller: widget.controller,
              editor: this,
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: {
                  TertiaryPanGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          TertiaryPanGestureRecognizer>(
                    () => TertiaryPanGestureRecognizer(),
                    (instance) {
                      instance.onUpdate = (details) {
                        dragViewport(details.delta);
                      };
                    },
                  ),
                  PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                      PanGestureRecognizer>(
                    () => PanGestureRecognizer(),
                    (PanGestureRecognizer instance) {
                      instance
                        ..onStart = (details) {
                          if (widget.selectionMode !=
                              CanvasSelectionMode.multiple) {
                            localSelection = null;
                          }
                          _activeMouseGesture ??= createMouseGesture();
                          _dragStart = details.localPosition;
                          _activeMouseGesture?.onDragStart(_dragStart!);
                        }
                        ..onUpdate = (details) {
                          _activeMouseGesture?.onDrag(
                              _dragStart!, details.localPosition);
                        }
                        ..onEnd = (details) {
                          _activeMouseGesture?.onDragRelease(
                              _dragStart!, details.localPosition);
                          _activeMouseGesture?.dispose();
                          _dragStart = null;
                          _activeMouseGesture = null;
                        }
                        ..onCancel = () {
                          _activeMouseGesture?.onDragCancel();
                          _activeMouseGesture?.dispose();
                          _dragStart = null;
                          _activeMouseGesture = null;
                        };
                    },
                  ),
                },
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, child) {
                    Matrix4 transform = getLocalToGlobalTransform();
                    return Stack(
                      key: _viewportKey,
                      fit: StackFit.passthrough,
                      children: [
                        Positioned.fill(
                            child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            print('onTap: canvas editor');
                            if (localSelection != null) {
                              localSelection = null;
                            }
                          },
                        )),
                        GroupWidget(
                          children: [
                            Transform(
                              transform: transform,
                              child: CanvasItemWidget(
                                state: _rootState,
                                // parentTransform: transform,
                              ),
                            ),
                          ],
                        ),
                        GroupWidget(
                          children: [
                            Transform(
                              transform: transform,
                              child: LayoutGridWidget(
                                state: _rootState,
                                editor: this,
                              ),
                            ),
                          ],
                        ),
                        for (var selected in _selections)
                          ListenableBuilder(
                            key: ValueKey(selected),
                            listenable: selected.groups,
                            builder: (context, child) {
                              return Stack(
                                fit: StackFit.passthrough,
                                children: selected.groups.value.map(
                                  (e) {
                                    return SelectionTransformControlWidget(
                                      key: ValueKey(e),
                                      parentTransform: transform,
                                      selectionGroup: e,
                                      zoom: widget.controller.value.zoom,
                                      selection: selected,
                                      editor: this,
                                    );
                                  },
                                ).toList(),
                              );
                            },
                          ),
                        for (var selection in _selectionBoxes)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: SelectionWidget(
                              selectionBox: selection,
                            ),
                          ),
                        // SnappingPointRenderer(
                        //     editor: this, parentTransform: transform),
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent &&
                                widget.scrollAsZoom) {
                              onPointerScroll(event, this);
                            }
                          },
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // CanvasHandler
  final List<Selection> _selections = [];
  final List<SelectionBox> _selectionBoxes = [];
  EditorDragGestureSession? _activeMouseGesture;

  @override
  Selection? get localSelection {
    for (var selection in _selections) {
      if (selection.client == SelectionClient.local) {
        return selection;
      }
    }
    return null;
  }

  @override
  set localSelection(Selection? selection) {
    _selections.removeWhere((s) => s.client == SelectionClient.local);
    if (selection != null) {
      _selections.add(selection);
    }
    setState(() {});
  }

  @override
  CanvasEditorTransform get transform => widget.controller.value;

  @override
  set transform(CanvasEditorTransform value) {
    widget.controller.value = value;
  }

  @override
  EditorDragGestureSession? get activeMouseGesture => _activeMouseGesture;

  @override
  List<SelectionBox> get activeSelectionClients =>
      List.unmodifiable(_selectionBoxes);

  @override
  List<Selection> get activeSelections => List.unmodifiable(_selections);

  @override
  void addSelection(Selection selection) {
    for (var i = 0; i < _selections.length; i++) {
      if (_selections[i].client == selection.client) {
        setState(() {
          _selections[i] = selection;
        });
        return;
      }
    }
    setState(() {
      _selections.add(selection);
    });
  }

  @override
  void addSelectionRect(SelectionBox client) {
    setState(() {
      _selectionBoxes.add(client);
    });
  }

  @override
  void addToLocalSelection(CanvasItemState item) {
    var selection = localSelection;
    if (selection == null) {
      selection = Selection(
        groups: [
          SelectionGroup(
            parent: item.parent!,
            selectedItems: [item],
          ),
        ],
        client: SelectionClient.local,
      );
    } else {
      selection.addSelection(item);
    }
  }

  @override
  EditorDragGestureSession createMouseGesture() {
    if (_activeMouseGesture != null) {
      _activeMouseGesture!.dispose();
    }
    var handler = widget.gesture.createState(editor: this);
    _activeMouseGesture = handler;
    return handler;
  }

  @override
  void selectFromRect(SelectionBox rect) {
    if (rect.rect.isEmpty) return;
    Path path = Path();
    path.addRect(rect.rect);
    path = path.transform(getGlobalToLocalTransform().storage);
    print('rect: ${path.getBounds()}');
    CanvasHitTestResult result = CanvasHitTestResult();
    selectTest(result, path);
    // 1. if object overlap with selection box, add to selection.
    // 2. but if one of the object children overlap with the selection box,
    //    to be considered as selected, now object must fully overlap with the selection box

    PolygonOverlapResult findHitTestResult(CanvasItemState item) {
      for (var entry in result.path) {
        if (entry.target == item && entry is CanvasPathHitTestEntry) {
          return entry.overlap;
        }
      }
      return PolygonOverlapResult.none;
    }

    List<CanvasItemState> selected = [];

    for (var entry in result.path) {
      if (entry is CanvasPathHitTestEntry) {
        var item = entry.target;
        bool hasAnyOverlapChildren = item is CanvasObjectState &&
            item.children.any((child) =>
                findHitTestResult(child) != PolygonOverlapResult.none);
        if ((hasAnyOverlapChildren &&
                entry.overlap == PolygonOverlapResult.full) ||
            (!hasAnyOverlapChildren &&
                entry.overlap != PolygonOverlapResult.none)) {
          selected.add(item);
        }
      }
    }

    var selection = Selection.fromSelection(selected);
    addSelection(selection);
  }

  @override
  void hitTest(CanvasHitTestResult result, Offset position) {
    _rootState.hitTest(result, position);
  }

  @override
  void selectTest(CanvasHitTestResult result, Path path) {
    _rootState.selectTest(result, path, widget.textDirection);
  }

  @override
  void removeSelection(Selection selection) {
    _selections.remove(selection);
  }

  @override
  void removeSelectionRect(SelectionBox client) {
    _selectionBoxes.remove(client);
  }

  @override
  void setToLocalSelection(CanvasItemState item) {
    if (item.parent == null) {
      // root
      return;
    }
    localSelection = Selection(
      groups: [
        SelectionGroup(
          parent: item.parent!,
          selectedItems: [item],
        ),
      ],
      client: SelectionClient.local,
    );
  }

  @override
  void stopMouseGesture(EditorDragGestureSession gesture) {
    if (_activeMouseGesture == gesture) {
      setState(() {
        _activeMouseGesture = null;
      });
    }
  }

  @override
  Matrix4 getLocalToGlobalTransform() {
    Size editorSize = _editorSize;
    Offset editorCenter = editorSize.center(Offset.zero);
    Matrix4 transform = Matrix4.identity();
    transform.translate(
      widget.controller.value.offset.dx,
      widget.controller.value.offset.dy,
    );
    transform.scale(widget.controller.value.zoom);
    transform.translate(
      editorCenter.dx,
      editorCenter.dy,
    );
    return transform;
  }

  @override
  Matrix4 getGlobalToLocalTransform() {
    Size editorSize = _editorSize;
    Offset editorCenter = editorSize.center(Offset.zero);
    Matrix4 transform = Matrix4.identity();
    transform.translate(
      -editorCenter.dx,
      -editorCenter.dy,
    );
    transform.scale(1 / widget.controller.value.zoom);
    transform.translate(
      -widget.controller.value.offset.dx,
      -widget.controller.value.offset.dy,
    );
    return transform;
  }

  @override
  Offset globalToLocal(Offset position) {
    Matrix4 transform = getGlobalToLocalTransform();
    return MatrixUtils.transformPoint(transform, position);
  }

  @override
  Offset localToGlobal(Offset position) {
    Matrix4 transform = getLocalToGlobalTransform();
    return MatrixUtils.transformPoint(transform, position);
  }

  @override
  void shiftViewport(Offset delta) {
    dragViewport(delta);
  }
}
