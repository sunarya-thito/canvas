import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasParentWidget extends StatelessWidget {
  final CanvasParentState item;
  final List<Widget> children;

  const CanvasParentWidget({
    super.key,
    required this.item,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final targetDrop = item.targetDrop;
    return ListenableBuilder(
      listenable: item,
      builder: (context, child) {
        return GroupWidget(
          passthrough: true,
          children: [
            ...children,
            if (targetDrop != null)
              for (var group in targetDrop.groups)
                for (var ghost in group.items)
                  Builder(
                    builder: (context) {
                      var commonParent = ghost.findCommonParent(item);
                      if (commonParent == null) {
                        return const SizedBox.shrink();
                      }
                      Matrix4 reparentedTransform = commonParent
                              .computeEditorGlobalTransform() *
                          ghost.computeEditorGlobalTransformUntil(commonParent);
                      return Transform(
                        transform: Matrix4.inverted(
                            item.computeEditorGlobalTransform()),
                        child: ghost.render(context,
                            transform: reparentedTransform),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }
}
