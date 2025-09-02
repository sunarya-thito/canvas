import 'package:canvas/canvas.dart';
import 'package:flutter/widgets.dart';

class CanvasText extends CanvasItem {
  TextSpan _textSpan;

  CanvasText({
    super.layoutData,
    super.locked,
    super.debugLabel,
    required TextSpan textSpan,
  }) : _textSpan = textSpan;

  @override
  CanvasItemState createState({CanvasParentState? parent}) {
    return CanvasTextState(item: this, parent: parent);
  }
}

class CanvasTextState extends CanvasItemState {
  late TextPainter _textPainter;
  CanvasTextState({required super.item, required super.parent}) {
    _textPainter = TextPainter(
      text: (item as CanvasText)._textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
  }

  void updateTextSpan(TextSpan textSpan) {
    _textPainter.text = textSpan;
  }

  @override
  void dispose() {
    super.dispose();
    _textPainter.dispose();
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _textPainter.layout(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _textPainter.layout(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _textPainter.layout();
    return _textPainter.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _textPainter.layout();
    return _textPainter.width;
  }
}
