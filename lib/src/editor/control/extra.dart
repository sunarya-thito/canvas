import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/selection/box.dart';
import 'package:flutter/widgets.dart';

class ExtraTransformationControlWidget extends StatelessWidget {
  final ExtraTransformationControl control;

  const ExtraTransformationControlWidget({
    super.key,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return control.render(context) ?? const SizedBox.shrink();
  }
}

abstract class ExtraTransformationControl {
  final CanvasEditor editor;
  final SelectionBox selectionBox;

  ExtraTransformationControl({
    required this.editor,
    required this.selectionBox,
  });

  Widget? render(BuildContext context);
}
