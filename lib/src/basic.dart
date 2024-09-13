import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class TextCanvasItem extends CanvasItemAdapter {
  final String text;
  final TextStyle style;
  final VoidCallback? onTap;

  TextCanvasItem._({
    required this.text,
    required this.style,
    super.transform,
    super.selected,
    this.onTap,
  });

  factory TextCanvasItem({
    required String text,
    TextStyle? style,
    Offset? offset,
    double? rotation,
    Size? size,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    style ??= const TextStyle();
    return TextCanvasItem._(
      text: text,
      style: style,
      transform: CanvasItemTransform(
        position: offset ?? Offset.zero,
        rotation: rotation ?? 0.0,
        size: size ?? measureText(text, style),
      ),
      selected: selected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      overflow: TextOverflow.visible,
    );
  }

  @override
  void onPressed() {
    onTap?.call();
  }

  static Size measureText(String text, TextStyle style,
      {TextDirection textDirection = TextDirection.ltr}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
    );
    textPainter.layout();
    return textPainter.size + const Offset(3, 0);
  }
}

class ImageCanvasItem extends CanvasItemAdapter {
  final ImageProvider image;
  final BoxFit fit;
  final VoidCallback? onTap;

  ImageCanvasItem({
    required this.image,
    this.fit = BoxFit.contain,
    super.transform,
    super.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Image(image: image, fit: fit);
  }

  @override
  void onPressed() {
    onTap?.call();
  }
}

class WidgetCanvasItem extends CanvasItemAdapter {
  final Widget child;
  final VoidCallback? onTap;

  WidgetCanvasItem({
    required this.child,
    super.transform,
    super.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  void onPressed() {
    onTap?.call();
  }
}

class BoxCanvasItem extends CanvasItemAdapter {
  final Color color;
  final double radius;
  final VoidCallback? onTap;

  BoxCanvasItem({
    required this.color,
    this.radius = 0.0,
    super.transform,
    super.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  void onPressed() {
    onTap?.call();
  }
}
