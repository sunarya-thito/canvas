import 'package:canvas/src/editor/editor.dart';

abstract class CanvasEvent {
  final CanvasEditor editor;

  const CanvasEvent({
    required this.editor,
  });
}
