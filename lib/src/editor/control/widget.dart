import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class EditorControlRecognizer extends StatelessWidget {
  final ValueGetter<EditorControlSession> sessionFactory;
  final Widget? child;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;
  final HitTestBehavior? behavior;

  const EditorControlRecognizer({
    super.key,
    required this.sessionFactory,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: onTap,
      onPanStart: (details) {
        final editorData = CanvasEditorWidgetData.find(context);
        final session = sessionFactory();
        editorData.editor.startControlSession(
            session,
            editorData.globalToLocal(details.globalPosition),
            editorData.viewportSize);
        onPanStart?.call(details);
      },
      onPanUpdate: (details) {
        onPanUpdate?.call(details);
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.updateControlSession(
          editorData.globalToLocal(details.globalPosition),
          editorData.viewportSize,
        );
      },
      onPanEnd: (details) {
        onPanEnd?.call(details);
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.endControlSession();
      },
      onPanCancel: () {
        onPanCancel?.call();
        final editorData = CanvasEditorWidgetData.find(context);
        editorData.editor.cancelControlSession();
      },
      child: child,
    );
  }
}
