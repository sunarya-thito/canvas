import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasContainer {
  CanvasItem operator [](int index);
  int get length;
  CanvasParentTransform get transform;
}

class CanvasItemPointer {
  final CanvasContainer container;
  final int index;

  CanvasItemPointer(this.container, this.index);

  CanvasItem get item => container[index];
}

abstract class CanvasParentTransform {
  Offset transformPoint(Offset point);
  CanvasItemTransform applyToChild(CanvasItemPointer target);
}

class CanvasItemTransform implements CanvasParentTransform {
  final Offset position;
  final Alignment anchor;
  final double rotation;
  final Size size;

  const CanvasItemTransform({
    this.position = Offset.zero,
    this.anchor = Alignment.center,
    this.rotation = 0,
    this.size = Size.zero,
  });

  CanvasItemTransform copyWith({
    Offset? position,
    Alignment? anchor,
    double? rotation,
    Size? size,
  }) {
    return CanvasItemTransform(
      position: position ?? this.position,
      anchor: anchor ?? this.anchor,
      rotation: rotation ?? this.rotation,
      size: size ?? this.size,
    );
  }

  Offset get anchorOffset {
    return anchor.alongSize(size);
  }

  Rect computePaintBounds() {
    var rectPoint = RectPoint.fromRect(Offset.zero & size);
    final anchorOffset = this.anchorOffset;
    // apply item transform
    rectPoint = rectPoint.translate(position);
    rectPoint = rectPoint.rotate(rotation);
    rectPoint = rectPoint.translate(-anchorOffset);
    return rectPoint.computeBounds();
  }

  @override
  CanvasItemTransform applyToChild(CanvasItemPointer target) {
    final child = target.item.transform;
    final anchorOffset = this.anchorOffset;
    var offset = child.position + position - anchorOffset;
    return child.copyWith(
      position: rotatePoint(offset, position, rotation),
      rotation: child.rotation + rotation,
    );
  }

  @override
  Offset transformPoint(Offset point) {
    final anchorOffset = this.anchorOffset;
    var offset = point + position - anchorOffset;
    return rotatePoint(offset, position, rotation);
  }
}

class CanvasTransform implements CanvasParentTransform {
  final Offset offset;
  final double scale;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.scale = 1,
  });

  CanvasTransform copyWith({
    Offset? offset,
    double? scale,
  }) {
    return CanvasTransform(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
    );
  }

  @override
  CanvasItemTransform applyToChild(CanvasItemPointer target) {
    final child = target.item.transform;
    return child.copyWith(
      position: (child.position - offset) / scale,
      size: child.size / scale,
    );
  }

  @override
  Offset transformPoint(Offset point) {
    return (point - offset) / scale;
  }
}

abstract class CanvasItem extends Listenable implements CanvasContainer {
  bool get selected;
  set selected(bool value);
  CanvasItemTransform get transform;
  set transform(CanvasItemTransform value);

  void paint(Canvas canvas);
  void onAttached();
  void onDetached();

  int _attachedCount = 0;
  bool get attached => _attachedCount > 0;

  Widget? buildOverlay(BuildContext context);

  List<CanvasItem> get children;
  set children(List<CanvasItem> value);

  Clip get clipBehavior;
  set clipBehavior(Clip value);

  @override
  CanvasItem operator [](int index) => children[index];

  @override
  int get length => children.length;
}

class CanvasViewportController extends ChangeNotifier {
  CanvasTransform _transform;

  CanvasViewportController({
    CanvasTransform transform = const CanvasTransform(),
  }) : _transform = transform;

  CanvasTransform get transform => _transform;

  set transform(CanvasTransform value) {
    if (value != _transform) {
      _transform = value;
      notifyListeners();
    }
  }
}

class CanvasViewport extends StatefulWidget {
  final List<CanvasItem> items;
  final CanvasViewportController controller;
  final bool multiSelect;
  final TransformControl transformControl;

  const CanvasViewport({
    Key? key,
    required this.items,
    required this.controller,
    this.multiSelect = false,
    this.transformControl = const StandardTransformControl(
      theme: StandardTransformControlThemeData(),
    ),
  }) : super(key: key);

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends State<CanvasViewport>
    implements CanvasContainer {
  late TransformControlHandler _transformControlHandler;
  late List<CanvasItem> _items;

  CanvasHitTestResult? _panHitTestResult;

  @override
  CanvasItem operator [](int index) => _items[index];

  @override
  int get length => _items.length;

  @override
  CanvasParentTransform get transform => widget.controller.transform;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _transformControlHandler = widget.transformControl.createHandler();
    for (var item in _items) {
      item.addListener(_handleItemChange);
      _handleItemAttach(item);
    }
  }

  @override
  void didUpdateWidget(CanvasViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transformControl != oldWidget.transformControl) {
      _transformControlHandler.dispose();
      _transformControlHandler = widget.transformControl.createHandler();
    }
    if (!listEquals(widget.items, _items)) {
      List<CanvasItem> oldItems = _items;
      _items = widget.items;
      // detach removed items
      for (var item in oldItems) {
        if (!_items.contains(item)) {
          item.removeListener(_handleItemChange);
          _handleItemDetach(item);
        }
      }
      // attach new items
      for (var item in _items) {
        if (!oldItems.contains(item)) {
          item.addListener(_handleItemChange);
          _handleItemAttach(item);
        }
      }
    }
  }

  void _visitItems(CanvasItem item, void Function(CanvasItemNode node) visitor,
      [CanvasItemNode? parent]) {
    var node = CanvasItemNode(item, parent: parent);
    visitor(node);
    for (var child in item.children) {
      _visitItems(child, visitor, node);
    }
  }

  void _visitAllItems(void Function(CanvasItemNode item) visitor) {
    for (var item in _items) {
      _visitItems(item, visitor);
    }
  }

  @override
  void dispose() {
    _transformControlHandler.dispose();
    for (var item in _items) {
      item.removeListener(_handleItemChange);
      _handleItemDetach(item);
    }
    super.dispose();
  }

  void _handleItemChange() {
    setState(() {});
  }

  void _handleItemAttach(CanvasItem item) {
    var attachedCount = item._attachedCount++;
    if (attachedCount == 0) {
      item.onAttached();
    }
  }

  void _handleItemDetach(CanvasItem item) {
    var attachedCount = --item._attachedCount;
    if (attachedCount == 0) {
      item.onDetached();
    }
  }

  void _handleTap(CanvasItem item) {
    if (widget.multiSelect) {
      item.selected = !item.selected;
    } else {
      _visitAllItems((node) {
        node.item.selected = node.item == item;
      });
    }
  }

  bool _isSelectionRoot(CanvasItemNode node) {
    // if (path.isEmpty) {
    //   return true;
    // }
    // for (var i = path.length - 1; i >= 0; i--) {
    //   if (path[i].selected) {
    //     return false;
    //   }
    // }
    // return true;
    if (node.parent == null) {
      return true;
    }
    var parent = node.parent;
    while (parent != null) {
      if (parent.item.selected) {
        return false;
      }
      parent = parent.parent;
    }
    return true;
  }

  CanvasHitTestResult? _hitTest(Offset pointer) {
    pointer = widget.controller.transform.transformPoint(pointer);
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = CanvasItemPointer(this, i);
      final transform = widget.controller.transform.applyToChild(item);
      final result = _hitTestChildren(pointer, item, transform);
      if (result.type != CanvasHitTestType.none) {
        return result;
      }
    }
    return null;
  }

  CanvasHitTestResult _hitTestChildren(Offset pointer,
      CanvasItemPointer itemPointer, CanvasItemTransform transform,
      {CanvasHitTestResult? parent}) {
    final item = itemPointer.item;
    final localPointer = transform.transformPoint(pointer);
    final bounds = transform.computePaintBounds();
    if (!bounds.contains(localPointer)) {
      return CanvasHitTestResult(
        type: CanvasHitTestType.none,
        itemPointer: itemPointer,
        position: localPointer,
        parent: parent,
      );
    }

    if (item.selected) {
      // test hit for transform control
      final transformControlHitResult = _transformControlHandler.hitTest(
          localPointer, widget.controller.transform, transform);
      if (transformControlHitResult != null) {
        return CanvasHitTestResult(
          type: transformControlHitResult,
          itemPointer: itemPointer,
          position: localPointer,
          parent: parent,
        );
      }
    }

    final children = item.children;
    for (var i = children.length - 1; i >= 0; i--) {
      final childPointer = CanvasItemPointer(itemPointer.item, i);
      final transform = item.transform.applyToChild(childPointer);
      final result =
          _hitTestChildren(pointer, childPointer, transform, parent: parent);
      if (result.type != CanvasHitTestType.none) {
        return result;
      }
    }
    return CanvasHitTestResult(
      type: CanvasHitTestType.self,
      itemPointer: itemPointer,
      position: localPointer,
      parent: parent,
    );
  }

  void _onPanStart(Offset offset) {
    // for (int i = 0; i < _items.length; i++) {
    //   var item = CanvasItemPointer(this, i);
    //   final result = _hitTest(offset);
    //   if (result.type != CanvasHitTestType.none) {
    //     _panHitTestResult = result;
    //     if (!result.itemPointer.itemPointer.selected) {
    //       _handleTap(result.itemPointer.itemPointer);
    //     }
    //     break;
    //   }
    // }
    _panHitTestResult = _hitTest(offset);
    if (_panHitTestResult != null) {
      if (!_panHitTestResult!.itemPointer.item.selected) {
        _handleTap(_panHitTestResult!.itemPointer.item);
      }
    }
  }

  void _onPanUpdate(Offset panDelta, Offset cursorPosition) {
    final result = _panHitTestResult;
    if (result != null) {
      final item = result.itemPointer;
      CanvasHitTestResult? parent = result.parent;
      while (parent != null) {
        panDelta =
            _rotateDelta(panDelta, -parent.itemPointer.item.transform.rotation);
        cursorPosition = rotatePoint(
            cursorPosition,
            parent.itemPointer.item.transform.position,
            parent.itemPointer.item.transform.rotation);
        parent = parent.parent;
      }
      switch (result.type) {
        case CanvasHitTestType.self:
          if (item.item.selected) {
            _visitItems(item.item, (node) {
              if (!_isSelectionRoot(node)) {
                return;
              }
              final item = node.item;
              item.transform = item.transform.copyWith(
                position: item.transform.position +
                    panDelta / widget.controller.transform.scale,
              );
            });
          }
          break;
        case CanvasHitTestType.rotation:
          final offset = transformHitPoint(cursorPosition,
              widget.controller.transform, item.item.transform, false, true);
          var angle = offset.direction + pi / 2;
          angle = snapRotation(angle);
          final diff = angle - item.item.transform.rotation;
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            item.transform = item.transform.copyWith(
              rotation: item.transform.rotation + diff,
            );
          });
          break;
        case CanvasHitTestType.top:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta =
                  _rotateDelta(Offset(0, delta.dy), item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width,
                  item.transform.size.height - delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.bottom:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta =
                  _rotateDelta(Offset(0, delta.dy), item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width,
                  item.transform.size.height + delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.left:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta =
                  _rotateDelta(Offset(delta.dx, 0), item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width - delta.dx,
                  item.transform.size.height,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.right:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta =
                  _rotateDelta(Offset(delta.dx, 0), item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width + delta.dx,
                  item.transform.size.height,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.topLeft:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta = _rotateDelta(delta, item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width - delta.dx,
                  item.transform.size.height - delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.topRight:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta = _rotateDelta(delta, item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width + delta.dx,
                  item.transform.size.height - delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.bottomLeft:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta = _rotateDelta(delta, item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width - delta.dx,
                  item.transform.size.height + delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        case CanvasHitTestType.bottomRight:
          var delta = panDelta / widget.controller.transform.scale;
          delta = _rotateDelta(delta, -item.item.transform.rotation);
          _visitItems(item.item, (node) {
            if (!_isSelectionRoot(node)) {
              return;
            }
            final item = node.item;
            if (item.selected) {
              var rotatedDelta = _rotateDelta(delta, item.transform.rotation);
              item.transform = item.transform.copyWith(
                size: Size(
                  item.transform.size.width + delta.dx,
                  item.transform.size.height + delta.dy,
                ),
                position: item.transform.position + rotatedDelta / 2,
              );
            }
          });
          break;
        default:
      }
      return;
    }
    // canvas drag
    widget.controller.transform = widget.controller.transform.copyWith(
      offset: widget.controller.transform.offset + panDelta,
    );
  }

  void _onPanStop() {
    _panHitTestResult = null;
  }

  void _onTapDown(Offset offset) {
    final result = _hitTest(offset);
    if (result != null) {
      _handleTap(result.itemPointer.item);
    } else if (!widget.multiSelect) {
      _visitAllItems((node) {
        node.item.selected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final delta = event.scrollDelta.dy > 0 ? 0.1 : -0.1;
                final newScale = widget.controller.transform.scale + delta;
                final position = event.localPosition;
                final before = (position - widget.controller.transform.offset) /
                    widget.controller.transform.scale;
                final newPosition = position - before * newScale;
                widget.controller.transform =
                    widget.controller.transform.copyWith(
                  scale: newScale,
                  offset: newPosition,
                );
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                _onTapDown(details.localPosition);
              },
              onPanStart: (details) {
                _onPanStart(details.localPosition);
              },
              onPanUpdate: (details) {
                _onPanUpdate(details.delta, details.localPosition);
              },
              onPanEnd: (details) {
                _onPanStop();
              },
              onPanCancel: () {
                _onPanStop();
              },
              child: CustomPaint(
                painter: CanvasPainter(
                  transform: widget.controller.transform,
                  items: _items,
                  transformControlHandler: _transformControlHandler,
                ),
              ),
            ),
          );
        });
  }
}

Offset _rotateDelta(Offset delta, double angle) {
  return Offset(
    delta.dx * cos(angle) - delta.dy * sin(angle),
    delta.dx * sin(angle) + delta.dy * cos(angle),
  );
}
