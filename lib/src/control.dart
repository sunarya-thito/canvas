import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class TransformControlThemeData {
  final Decoration macroDecoration;
  final Decoration microDecoration;
  final Decoration macroScaleDecoration;
  final Decoration microScaleDecoration;
  final Decoration selectionDecoration;
  final BorderSide rotationLineBorder;
  final double rotationLineLength;
  final Decoration rotationHandleDecoration;

  final Size rotationHandleSize;
  final Size macroSize;
  final Size microSize;

  const TransformControlThemeData({
    required this.macroDecoration,
    required this.microDecoration,
    required this.macroScaleDecoration,
    required this.microScaleDecoration,
    required this.selectionDecoration,
    required this.rotationLineBorder,
    required this.rotationLineLength,
    required this.rotationHandleDecoration,
    required this.rotationHandleSize,
    required this.macroSize,
    required this.microSize,
  });

  factory TransformControlThemeData.defaultThemeData() {
    return TransformControlThemeData(
      macroDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFFFFFF),
      ),
      microDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFFFFFF),
      ),
      macroScaleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFF0000),
      ),
      microScaleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        color: const Color(0xFFFF0000),
      ),
      selectionDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
      ),
      rotationLineBorder: const BorderSide(color: Color(0xFF000000), width: 1),
      rotationLineLength: 20,
      rotationHandleDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        shape: BoxShape.circle,
        color: const Color(0xFFFFFFFF),
      ),
      rotationHandleSize: const Size(10, 10),
      macroSize: const Size(10, 10),
      microSize: const Size(8, 8),
    );
  }
}

typedef UnaryOpertor<T> = T Function(T value);

enum ResizeMode {
  none,
  scale,
  resize,
}

class TransformControl extends StatefulWidget {
  final CanvasTransform transform;
  final UnaryOpertor<CanvasTransform>? onChanging;
  final ValueChanged<CanvasTransform>? onChanged;
  final TransformControlThemeData? themeData;
  final ResizeMode resizeMode;
  final bool canRotate;
  final bool canDrag;

  const TransformControl({
    super.key,
    required this.transform,
    this.onChanging,
    this.onChanged,
    this.themeData,
    this.resizeMode = ResizeMode.resize,
    this.canRotate = true,
    this.canDrag = true,
  });

  @override
  State<TransformControl> createState() => _TransformControlState();
}

class _TransformControlState extends State<TransformControl> {
  late CanvasTransform _transform;

  @override
  void initState() {
    super.initState();
    _transform = widget.transform;
  }

  void _endResize() {
    if (widget.onChanged != null) {
      widget.onChanged!(_transform);
    }
    _transform = widget.transform;
  }

  set _newTransform(CanvasTransform value) {
    setState(() {
      _transform = widget.onChanging?.call(value) ?? value;
    });
  }

  void _drag(Offset delta) {
    _newTransform = _transform.copyWith(offset: _transform.offset + delta);
  }

  @override
  void didUpdateWidget(TransformControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // _transform = widget.transform;
  }

  Size _normalizeSize(Size size) {
    return Size(
        size.width < 0 ? 0 : size.width, size.height < 0 ? 0 : size.height);
  }

  Offset _rotate(Offset point, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      point.dx * cosA - point.dy * sinA,
      point.dx * sinA + point.dy * cosA,
    );
  }

  void _resizeTopLeft(Offset delta) {
    delta = _rotate(delta, _transform.rotation);
    print('resize top left: $delta');
    if (_isScale) {
    } else {
      _newTransform = _transform.copyWith(
        size: _normalizeSize(Size(_transform.size.width - delta.dx,
            _transform.size.height - delta.dy)),
        offset: _transform.offset + delta * 0.5,
      );
    }
  }

  /// if _isScale is true, use scale instead of size
  bool get _isScale => widget.resizeMode == ResizeMode.scale;

  void _resizeTopRight(Offset delta) {}

  void _resizeBottomLeft(Offset delta) {}

  void _resizeBottomRight(Offset delta) {}

  void _resizeTop(Offset delta) {}

  void _resizeBottom(Offset delta) {}

  void _resizeLeft(Offset delta) {}

  void _resizeRight(Offset delta) {}

  @override
  Widget build(BuildContext context) {
    var themeData =
        widget.themeData ?? TransformControlThemeData.defaultThemeData();
    var transform = _transform;
    final origin = transform.alignment.alongSize(transform.scaledSize);
    return Transform(
      transform: transform.nonScalingMatrix,
      child: ConstrainedCanvasItem(
        transform: transform.scaledSize,
        child: CanvasGroup(children: [
          // selection box
          CanvasItem(
            transform: CanvasTransform(
              size: transform.scaledSize,
              offset: origin,
            ),
            background: MouseRegion(
              cursor: widget.canDrag
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onPanUpdate: (details) {
                  _drag(details.delta);
                },
                onPanEnd: (details) {
                  _endResize();
                },
                child: Container(
                  decoration: themeData.selectionDecoration,
                ),
              ),
            ),
          ),
          // rotation line
          if (widget.canRotate)
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(transform.scaledSize.width / 2,
                    -themeData.rotationLineLength / 2),
                size: Size(1, themeData.rotationLineLength),
              ),
              background: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: themeData.rotationLineBorder,
                  ),
                ),
              ),
            ),
          // rotation handle
          if (widget.canRotate)
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(
                    transform.scaledSize.width /
                        2, // the half of the border width
                    -themeData.rotationLineLength -
                        themeData.rotationHandleSize.height / 2),
                size: themeData.rotationHandleSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: GestureDetector(
                  child: Container(
                    decoration: themeData.rotationHandleDecoration,
                  ),
                ),
              ),
            ),
          // top left
          if (widget.resizeMode != ResizeMode.none) ...[
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset.zero,
                size: themeData.macroSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeft,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeTopLeft(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    // decoration: themeData.macroDecoration,
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.macroDecoration
                        : themeData.macroScaleDecoration,
                  ),
                ),
              ),
            ),
            // top right
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(transform.scaledSize.width, 0),
                size: themeData.macroSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeUpRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeTopRight(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    // decoration: themeData.macroDecoration,
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.macroDecoration
                        : themeData.macroScaleDecoration,
                  ),
                ),
              ),
            ),
            // bottom left
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(0, transform.scaledSize.height),
                size: themeData.macroSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeDownLeft,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeBottomLeft(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    // decoration: themeData.macroDecoration,
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.macroDecoration
                        : themeData.macroScaleDecoration,
                  ),
                ),
              ),
            ),
            // bottom right
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(
                    transform.scaledSize.width, transform.scaledSize.height),
                size: themeData.macroSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeBottomRight(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    // decoration: themeData.macroDecoration,
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.macroDecoration
                        : themeData.macroScaleDecoration,
                  ),
                ),
              ),
            ),
            // top
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(transform.scaledSize.width / 2, 0),
                size: themeData.microSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeTop(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.microDecoration
                        : themeData.microScaleDecoration,
                  ),
                ),
              ),
            ),
            // bottom
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(transform.scaledSize.width / 2,
                    transform.scaledSize.height),
                size: themeData.microSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeBottom(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.microDecoration
                        : themeData.microScaleDecoration,
                  ),
                ),
              ),
            ),
            // left
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(0, transform.scaledSize.height / 2),
                size: themeData.microSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeLeft(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.microDecoration
                        : themeData.microScaleDecoration,
                  ),
                ),
              ),
            ),
            // right
            CanvasItem(
              transform: CanvasTransform(
                offset: Offset(transform.scaledSize.width,
                    transform.scaledSize.height / 2),
                size: themeData.microSize,
              ),
              background: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeRight(details.delta);
                  },
                  onPanEnd: (details) {
                    _endResize();
                  },
                  child: Container(
                    decoration: widget.resizeMode == ResizeMode.resize
                        ? themeData.microDecoration
                        : themeData.microScaleDecoration,
                  ),
                ),
              ),
            ),
          ]
        ]),
      ),
    );
  }
}
