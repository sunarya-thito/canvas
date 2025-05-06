import 'package:canvas/canvas.dart';
import 'package:canvas/old_src/external/widgets.dart';
import 'package:flutter/widgets.dart';

abstract class LayoutGrid {
  const LayoutGrid();
  void paint(
    CanvasEditor editor,
    Canvas canvas,
    Size size,
  );
  bool shouldRepaint(covariant LayoutGrid oldDelegate);
}

class GridLayoutGrid extends LayoutGrid {
  final Color color;
  final double spacing;
  final double strokeWidth;
  final Alignment alignment;

  const GridLayoutGrid({
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.spacing = 10.0,
    this.strokeWidth = 1.0,
    this.alignment = Alignment.topLeft,
  });

  @override
  void paint(CanvasEditor editor, Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth / editor.transform.zoom
      ..style = PaintingStyle.stroke;

    final Offset offset = alignment.alongSize(size);

    for (double x = -offset.dx % spacing; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = -offset.dy % spacing; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GridLayoutGrid oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.alignment != alignment;
  }
}

enum BlockType {
  stretch,
  start,
  center,
  end,
}

class BlockLayoutGrid extends LayoutGrid {
  final int count;
  final Color color;
  final BlockType type;
  final double size; // only for start, center, end
  final double offset; // only for start, end
  final double gutter; // only for start, center, end, stretch
  final double margin; // only for stretch
  final Axis direction;

  const BlockLayoutGrid({
    this.count = 1,
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.type = BlockType.stretch,
    this.size = 10.0,
    this.offset = 0.0,
    this.gutter = 0.0,
    this.margin = 0.0,
    this.direction = Axis.horizontal,
  });

  const BlockLayoutGrid.start({
    this.count = 1,
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.size = 10.0,
    this.offset = 0.0,
    this.gutter = 0.0,
    this.direction = Axis.horizontal,
  })  : margin = 0.0,
        type = BlockType.start;

  const BlockLayoutGrid.center({
    this.count = 1,
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.size = 10.0,
    this.gutter = 0.0,
    this.direction = Axis.horizontal,
  })  : margin = 0.0,
        offset = 0.0,
        type = BlockType.center;

  const BlockLayoutGrid.end({
    this.count = 1,
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.size = 10.0,
    this.offset = 0.0,
    this.gutter = 0.0,
    this.direction = Axis.horizontal,
  })  : margin = 0.0,
        type = BlockType.end;

  const BlockLayoutGrid.stretch({
    this.count = 1,
    this.color = const Color.fromARGB(122, 255, 0, 0),
    this.margin = 0.0,
    this.gutter = 0.0,
    this.direction = Axis.horizontal,
  })  : size = 0.0,
        offset = 0.0,
        type = BlockType.stretch;

  @override
  void paint(CanvasEditor editor, Canvas canvas, Size size) {
    if (count == 0) return;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // assume its horizontal, then later rotate it
    if (direction == Axis.vertical) {
      size = Size(size.height, size.width);
    }

    size = Size(size.width - margin * 2, size.height);

    double blockWidth = type == BlockType.stretch
        ? (size.width - gutter * (count - 1)) / count
        : this.size;
    double blockHeight = size.height;

    for (int i = 0; i < count; i++) {
      double x;
      switch (type) {
        case BlockType.stretch:
          x = i * (blockWidth + gutter) + margin;
          break;
        case BlockType.start:
          x = offset + margin + i * (blockWidth + gutter);
          break;
        case BlockType.center:
          x = i * (blockWidth + gutter) +
              margin +
              (size.width - (blockWidth * count + gutter * (count - 1))) / 2;
          break;
        case BlockType.end:
          x = size.width -
              blockWidth -
              offset -
              margin -
              (count - 1 - i) * (blockWidth + gutter);
          break;
      }

      Rect rect;
      switch (direction) {
        case Axis.horizontal:
          rect = Rect.fromLTWH(x, 0, blockWidth, blockHeight);
          break;
        case Axis.vertical:
          rect = Rect.fromLTWH(0, x, blockHeight, blockWidth);
          break;
      }

      canvas.drawRect(
        rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlockLayoutGrid oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.color != color ||
        oldDelegate.type != type ||
        oldDelegate.size != size ||
        oldDelegate.offset != offset ||
        oldDelegate.gutter != gutter ||
        oldDelegate.margin != margin;
  }
}

class _LayoutGridPainter extends CustomPainter {
  final CanvasEditor editor;
  final LayoutGrid layoutGrid;

  const _LayoutGridPainter({
    required this.layoutGrid,
    required this.editor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    layoutGrid.paint(editor, canvas, size);
  }

  @override
  bool shouldRepaint(covariant _LayoutGridPainter oldDelegate) {
    return oldDelegate.layoutGrid.shouldRepaint(layoutGrid) ||
        oldDelegate.editor != editor;
  }
}

class LayoutGridWidget extends StatelessWidget {
  final CanvasItemState state;
  final CanvasEditor editor;
  final Matrix4? overrideTransform;

  const LayoutGridWidget({
    super.key,
    required this.state,
    required this.editor,
    this.overrideTransform,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        var state = this.state;
        if (state is! CanvasObjectState) {
          return SizedBox.shrink();
        }
        Matrix4 transform = overrideTransform ?? state.transform;
        Offset? editorOffset = state.editorOffset;
        if (editorOffset != null && overrideTransform == null) {
          transform.translate(editorOffset.dx, editorOffset.dy);
        }
        bool clipContent = state.item.clipContent;
        BorderRadiusGeometry? borderRadius = state.item.borderRadius;
        return Visibility(
          visible: state.targetReparent == null || overrideTransform != null,
          child: Transform(
            transform: transform,
            child: AdaptiveSizedBox(
              size: state.size,
              child: FreeHitClipRRect(
                borderRadius: borderRadius ?? BorderRadius.zero,
                clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
                child: GroupWidget(
                  passthrough: true,
                  children: [
                    for (var layoutGrid in state.item.layoutGrids)
                      CustomPaint(
                        painter: _LayoutGridPainter(
                          editor: editor,
                          layoutGrid: layoutGrid,
                        ),
                      ),
                    IgnorePointer(
                      child: ListenableBuilder(
                        listenable: Listenable.merge(state.children),
                        builder: (context, child) {
                          return GroupWidget(
                            children: [
                              for (var child in state.children)
                                LayoutGridWidget(
                                  key: ValueKey(child),
                                  editor: editor,
                                  state: child,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: state.targetDrop,
                      builder: (context, value, _) {
                        if (value == null) {
                          return GroupWidget();
                        }
                        return GroupWidget(
                          children: [
                            for (var group in value.groups)
                              for (var ghost in group.selectedItems)
                                Builder(
                                  builder: (context) {
                                    var commonParent =
                                        ghost.findCommonParent(state);
                                    if (commonParent == null) {
                                      return SizedBox.shrink();
                                    }
                                    Matrix4 reparentedTransform =
                                        commonParent.globalEditorTransform *
                                            ghost.getGlobalEditorTransformUntil(
                                                commonParent);
                                    return Transform(
                                      transform: Matrix4.inverted(
                                          state.globalTransform),
                                      child: LayoutGridWidget(
                                        state: ghost,
                                        editor: editor,
                                        overrideTransform: reparentedTransform,
                                      ),
                                    );
                                  },
                                )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
