import 'dart:ui';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/selection/selection.dart';
import 'package:flutter/widgets.dart';

class _ExtraTransformationControlPainter extends CustomPainter {
  final ExtraTransformationControl control;

  _ExtraTransformationControlPainter(this.control) : super(repaint: control);

  @override
  void paint(Canvas canvas, Size size) {
    control.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // will repaint whenever the control notifies listeners
  }

  @override
  bool? hitTest(Offset position) {
    return control.hitTest(position);
  }
}

class ExtraTransformationControlWidget extends StatelessWidget {
  final ExtraTransformationControl control;

  const ExtraTransformationControlWidget({
    super.key,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.deferToChild,
      cursor: control.cursor?.cursor ?? SystemMouseCursors.basic,
      onEnter: (event) => control.onMouseEnter(event.localPosition),
      onExit: (event) => control.onMouseExit(event.localPosition),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanStart: (details) => control.onDragStart(),
        onPanUpdate: (details) => control.onDragUpdate(details.delta),
        onPanEnd: (details) => control.onDragEnd(),
        onPanCancel: () => control.onDragCancel(),
        onTap: () => control.onTap(),
        child: CustomPaint(
          painter: _ExtraTransformationControlPainter(control),
          child: control.render(context),
        ),
      ),
    );
  }
}

abstract class ExtraTransformationControl extends ChangeNotifier {
  final CanvasEditorHandler editor;

  ExtraTransformationControl({
    required this.editor,
  });

  void markNeedsRepaint() {
    notifyListeners();
  }

  Widget? render(BuildContext context);

  void paint(Canvas canvas, Size size);

  bool hitTest(Offset position);
  void onDragStart() {}
  void onDragUpdate(Offset delta) {}
  void onDragEnd() {}
  void onDragCancel() {}
  void onMouseEnter(Offset position) {}
  void onMouseExit(Offset position) {}
  void onTap() {}

  DirectionalCursor? get cursor;
}
