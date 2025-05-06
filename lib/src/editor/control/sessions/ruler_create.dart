import 'package:canvas/src/editor/control/sessions/ruler.dart';
import 'package:canvas/src/editor/ruler/ruler.dart';
import 'package:canvas/src/editor/snap/ruler.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';

class RulerCreateSnapAnchorControlSession extends RulerSnappingControlSession {
  final Axis direction;
  late CanvasSnapGuideline _snapAnchor;

  RulerCreateSnapAnchorControlSession({
    required this.direction,
  });

  @override
  CanvasSnapGuideline get snapAnchor => _snapAnchor;

  @override
  void visitSnapAnchor(SnapAnchorVisitor visitor) {
    int index = 0;
    var list = editor.rulerSnapAnchors;
    visitor(
      CanvasRulerSnapAnchor(
        offset: direction == Axis.horizontal ? delta.endY : delta.endX,
        direction: direction,
        crossLineVisitor: () {
          while (index < list.length) {
            var item = list[index];
            if (item.axis != direction) {
              return item.offset;
            }
            index++;
          }
          return null;
        },
      ),
    );
  }

  @override
  void onDragStart() {
    _snapAnchor = editor.createRulerSnapAnchor(
        direction == Axis.horizontal ? delta.startY : delta.startX, direction);
  }

  @override
  void onDragUpdate() {
    _snapAnchor.offset = direction == Axis.horizontal ? delta.endY : delta.endX;
  }

  @override
  void onDragEnd() {
    if (!this.delta.hasChanged) {
      editor.removeRulerSnapAnchor(_snapAnchor);
      return;
    }
    double delta = snapAnchor.axis == Axis.horizontal
        ? this.delta.deltaY
        : this.delta.deltaX;
    if (delta < 1) {
      editor.removeRulerSnapAnchor(_snapAnchor);
      return;
    }
    double offset = snapAnchor.offset * editor.zoom +
        (snapAnchor.axis == Axis.horizontal
            ? (viewportSize.height / 2 * editor.zoom + editor.offset.dy)
            : (viewportSize.width / 2 * editor.zoom + editor.offset.dx));
    if (offset < 0 ||
        (snapAnchor.axis == Axis.horizontal && offset > viewportSize.height) ||
        (snapAnchor.axis == Axis.vertical && offset > viewportSize.width)) {
      editor.removeRulerSnapAnchor(_snapAnchor);
      return;
    }
    // TODO: send update event to editor
  }

  @override
  void onDragCancel() {
    editor.removeRulerSnapAnchor(_snapAnchor);
  }
}
