import 'package:canvas/canvas.dart';
import 'package:canvas/src/editor/ruler/ruler.dart';

abstract class RulerSnappingControlSession extends EditorControlSession {
  CanvasSnapGuideline get snapAnchor;
  @override
  bool get shiftViewport => false;
}
