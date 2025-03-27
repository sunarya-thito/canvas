import 'package:canvas/canvas.dart';
import 'package:canvas/src/actions.dart';
import 'package:flutter/widgets.dart';

class CanvasEditor extends StatefulWidget {
  final CanvasEditorController controller;
  final EditorGestureHandler gestureHandler;
  final List<CanvasItem> items;
  final TextDirection textDirection;

  const CanvasEditor({
    super.key,
    required this.controller,
    this.gestureHandler = const DesktopEditorGestureHandler(),
    this.items = const [],
    this.textDirection = TextDirection.ltr,
  });

  @override
  State<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends State<CanvasEditor> {
  // The size of the root does not really matter.
  // But it must not be zero, otherwise flutter will not render the widget.
  static const rootConstraints = BoxConstraints.tightFor(height: 1, width: 1);
  late CanvasRoot _root;
  late CanvasItemState _rootState;

  @override
  void initState() {
    super.initState();
    _root = CanvasRoot(debugLabel: 'root');
    _root.children = widget.items;
    _rootState = _root.createState();
    _root.attach(_rootState);
    _performFullLayout();
    _rootState.addListener(_performFullLayout);
  }

  void _performFullLayout() {
    print('Performing full layout');
    _rootState.layout(rootConstraints, widget.textDirection);
    print('Root size: ${_rootState.size}');
  }

  @override
  void didUpdateWidget(covariant CanvasEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _root.children = widget.items;
  }

  @override
  void dispose() {
    _rootState.removeListener(_performFullLayout);
    _root.detach(_rootState);
    _root.children = const [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(_rootState.hasSize, 'Root object has not been laid out');
    return BoundingBoxDebugger(
      child: Actions(
        actions: {
          CanvasUpdateLayoutDataIntent: Action.overridable(
            defaultAction: CanvasUpdateLayoutDataAction(),
            context: context,
          ),
          CanvasUpdateChildrenIntent: Action.overridable(
            defaultAction: CanvasUpdateChildrenAction(),
            context: context,
          ),
        },
        child: widget.gestureHandler.wrap(
          context,
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              Matrix4 transform = Matrix4.identity();
              transform.translate(
                widget.controller.value.offset.dx,
                widget.controller.value.offset.dy,
              );
              transform.scale(widget.controller.value.zoom);
              return Transform(
                transform: transform,
                child: GroupWidget(
                  size: Size.zero,
                  children: [
                    CanvasItemWidget(
                      state: _rootState,
                    ),
                    CanvasBoundingBoxWidget(
                      state: _rootState,
                    ),
                    CanvasBoundingBoxMetadataWidget(state: _rootState),
                  ],
                ),
              );
            },
          ),
          widget.controller,
        ),
      ),
    );
  }
}
