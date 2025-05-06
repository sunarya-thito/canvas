import 'package:canvas/src/editor/control/sessions/ruler.dart';
import 'package:canvas/src/editor/ruler/ruler.dart';
import 'package:canvas/src/editor/snap/ruler.dart';
import 'package:canvas/src/editor/snap/snap.dart';
import 'package:flutter/widgets.dart';

class RulerUpdateSnapAnchorControlSession extends RulerSnappingControlSession {
  @override
  final CanvasSnapGuideline snapAnchor;

  RulerUpdateSnapAnchorControlSession({
    required this.snapAnchor,
  });

  @override
  void visitSnapAnchor(SnapAnchorVisitor visitor) {
    int index = 0;
    var list = editor.rulerSnapAnchors;
    visitor(
      CanvasRulerSnapAnchor(
        offset: snapAnchor.axis == Axis.horizontal ? delta.endY : delta.endX,
        direction: snapAnchor.axis,
        crossLineVisitor: snapAnchor.axis == Axis.horizontal
            ? () {
                while (index < list.length) {
                  var item = list[index];
                  if (item.axis == Axis.vertical) {
                    return item.offset;
                  }
                  index++;
                }
                return null;
              }
            : () {
                while (index < list.length) {
                  var item = list[index];
                  if (item.axis == Axis.horizontal) {
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
  void onDragUpdate() {
    snapAnchor.offset =
        snapAnchor.axis == Axis.horizontal ? delta.endY : delta.endX;

    double offset = snapAnchor.offset * editor.zoom +
        (snapAnchor.axis == Axis.horizontal
            ? (viewportSize.height / 2 * editor.zoom + editor.offset.dy)
            : (viewportSize.width / 2 * editor.zoom + editor.offset.dx));
    if (offset < 0 ||
        (snapAnchor.axis == Axis.horizontal && offset > viewportSize.height) ||
        (snapAnchor.axis == Axis.vertical && offset > viewportSize.width)) {
      editor.removeRulerSnapAnchor(snapAnchor);
      return;
    }
    // TODO: send update event to editor
  }

  @override
  void onDragCancel() {
    super.onDragCancel();
    double delta =
        snapAnchor.axis == Axis.horizontal ? this.delta.endY : this.delta.endX;
    snapAnchor.offset -= delta;
  }
}
