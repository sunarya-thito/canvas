import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasEditorControlRecognizer extends StatelessWidget {
  final ValueGetter<EditorControlSession> sessionFactory;
  final Widget? child;

  const CanvasEditorControlRecognizer({
    super.key,
    required this.sessionFactory,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final editorData = CanvasEditorWidgetData.find(context);
        final session = sessionFactory();
        editorData.editor.startControlSession(
            session,
            editorData.globalToLocal(details.globalPosition),
            editorData.viewportSize);
      },
      onPanUpdate: (details) {
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.updateControlSession(
          editorData.globalToLocal(details.globalPosition),
          editorData.viewportSize,
        );
      },
      onPanEnd: (details) {
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.endControlSession();
      },
      onPanCancel: () {
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.cancelControlSession();
      },
      child: child,
    );
  }
}
