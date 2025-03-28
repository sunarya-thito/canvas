import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/actions.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:canvas/src/selection/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/gestures/hit_test.dart';
import 'package:flutter/widgets.dart';

class CanvasEditor extends StatefulWidget {
  final CanvasEditorController controller;
  final EditorGesture gesture;
  final CanvasRoot root;
  final TextDirection textDirection;
  final CanvasSelectionMode selectionMode;
  final FocusNode? focusNode;

  const CanvasEditor({
    super.key,
    required this.controller,
    this.gesture = const EditorMoveGesture(),
    required this.root,
    this.textDirection = TextDirection.ltr,
    this.selectionMode = CanvasSelectionMode.single,
    this.focusNode,
  });

  @override
  State<CanvasEditor> createState() => CanvasEditorState();
}

class CanvasEditorState extends State<CanvasEditor>
    with TickerProviderStateMixin, CanvasEditorHandler {
  // The size of the root does not really matter.
  // But it must not be zero, otherwise flutter will not render the widget.
  static const rootConstraints = BoxConstraints.tightFor(height: 1, width: 1);
  late CanvasRoot _root;
  late CanvasRootState _rootState;
  late FocusNode _focusNode;
  late Size _editorSize;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _root = widget.root;
    _rootState = _root.createState();
    _root.attach(_rootState);
    _performFullLayout();
    _rootState.addListener(_performFullLayout);
  }

  void _performFullLayout() {
    _rootState.layout(rootConstraints, widget.textDirection);
  }

  @override
  void didUpdateWidget(covariant CanvasEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root) {
      _rootState.removeListener(_performFullLayout);
      _root.detach(_rootState);
      _root = widget.root;
      _rootState = _root.createState();
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

  @override
  Widget build(BuildContext context) {
    assert(_rootState.hasSize, 'Root object has not been laid out');
    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPointerCancel: (event) {
          _activeMouseGesture?.onPointerCancel(event);
        },
        onPointerUp: (event) {
          _activeMouseGesture?.onPointerUp(event);
        },
        onPointerMove: (event) {
          _activeMouseGesture?.onPointerMove(event);
        },
        onPointerDown: (event) {
          _focusNode.requestFocus();
          if (event.buttons == kPrimaryButton ||
              event.buttons == kSecondaryButton) {
            CanvasItemState? targetClick =
                findItemAtPosition(MatrixUtils.transformPoint(
              getGlobalToLocalTransform(),
              event.localPosition,
            ));
            if (targetClick != null) {
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
          }
          _activeMouseGesture ??= createMouseGesture(event.localPosition);
          _activeMouseGesture?.onPointerDown(event);
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            widget.gesture.onPointerScroll(event, this);
          }
        },
        child: Actions(
          actions: {
            CanvasUpdateLayoutDataIntent: Action.overridable(
              defaultAction: CanvasUpdateLayoutDataAction(),
              context: context,
            ),
            CanvasUpdateChildrenIntent: Action.overridable(
              defaultAction: CanvasUpdateChildrenAction(),
              context: context,
            ),
          },
          child: LayoutBuilder(builder: (context, constraints) {
            _editorSize = constraints.biggest;
            return ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                Matrix4 transform = getLocalToGlobalTransform();
                return Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Transform(
                      transform: transform,
                      child: CanvasItemWidget(
                        state: _rootState,
                      ),
                    ),
                    for (var selected in _selections)
                      ListenableBuilder(
                        listenable: selected.groups,
                        builder: (context, child) {
                          return Stack(
                            fit: StackFit.passthrough,
                            children: selected.groups.value.map(
                              (e) {
                                return SelectionTransformControlWidget(
                                    parentTransform: transform,
                                    selectionGroup: e);
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
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }

  // CanvasHandler
  final List<Selection> _selections = [];
  final List<SelectionBox> _selectionBoxes = [];
  EditorGestureState? _activeMouseGesture;

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
  EditorGestureState? get activeMouseGesture => _activeMouseGesture;

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
  EditorGestureState createMouseGesture(Offset localPosition) {
    if (_activeMouseGesture != null) {
      _activeMouseGesture!.dispose();
    }
    var handler =
        widget.gesture.createState(localPosition: localPosition, editor: this);
    _activeMouseGesture = handler;
    return handler;
  }

  @override
  void selectFromRect(SelectionBox rect) {
    if (rect.rect.isEmpty) return;
    Polygon polygon = Polygon.fromRect(rect.rect);
    polygon = polygon.transform(getGlobalToLocalTransform());
    CanvasHitTestResult result = CanvasHitTestResult();
    hitTestPolygon(result, polygon);
    // 1. if object overlap with selection box, add to selection.
    // 2. but if one of the object children overlap with the selection box,
    //    to be considered as selected, now object must fully overlap with the selection box

    PolygonOverlapResult findHitTestResult(CanvasItemState item) {
      for (var entry in result.path) {
        if (entry.target == item && entry is CanvasPolygonHitTestEntry) {
          return entry.overlap;
        }
      }
      return PolygonOverlapResult.none;
    }

    List<CanvasItemState> selected = [];

    for (var entry in result.path) {
      if (entry is CanvasPolygonHitTestEntry) {
        var item = entry.target;
        bool hasAnyOverlapChildren = item is CanvasObjectState &&
            item.children.any((child) =>
                findHitTestResult(child) != PolygonOverlapResult.none);
        print(
            'test: ${item.item.debugLabel} -> $hasAnyOverlapChildren & ${entry.overlap.name}');
        if ((hasAnyOverlapChildren &&
                entry.overlap == PolygonOverlapResult.full) ||
            (!hasAnyOverlapChildren &&
                entry.overlap != PolygonOverlapResult.none)) {
          selected.add(item);
        }
      }
    }

    var selection = Selection.fromSelection(selected);
    print('selection: $selected');
    addSelection(selection);
  }

  @override
  void hitTest(CanvasHitTestResult result, Offset position) {
    _rootState.hitTest(result, position);
  }

  @override
  void hitTestPolygon(CanvasHitTestResult result, Polygon polygon) {
    _rootState.selectTest(result, polygon);
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
  void stopMouseGesture(EditorGestureState gesture) {
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
}
