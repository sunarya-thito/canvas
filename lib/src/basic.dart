import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class CanvasItemAdapter extends CanvasItem with ChangeNotifier {
  bool _selected;
  CanvasItemTransform _transform;
  List<CanvasItem> _children = [];
  Clip _clip;
  CanvasItem? _parent;

  CanvasItemAdapter({
    bool selected = false,
    CanvasItemTransform transform = const CanvasItemTransform(),
    List<CanvasItem> children = const [],
    Clip clip = Clip.none,
  })  : _selected = selected,
        _transform = transform,
        _children = List.from(children),
        _clip = clip {
    for (final child in _children) {
      child.addListener(_handleChildChange);
    }
  }

  @override
  List<CanvasItem> get children => List.unmodifiable(_children);

  @override
  set children(List<CanvasItem> value) {
    if (!listEquals(value, _children)) {
      List<CanvasItem> oldChildren = _children;
      for (final child in oldChildren) {
        child.removeListener(_handleChildChange);
      }
      _children = List.from(value);
      for (final child in _children) {
        child.addListener(_handleChildChange);
      }
      if (attached) {
        for (final child in oldChildren) {
          if (!_children.contains(child)) {
            child.onDetached();
          }
        }
        for (final child in _children) {
          if (!oldChildren.contains(child)) {
            child.onAttached();
          }
        }
      }
      notifyListeners();
    }
  }

  void _handleChildChange() {
    notifyListeners();
  }

  @override
  bool get selected => _selected;

  @override
  CanvasItemTransform get transform => _transform;

  @override
  set selected(bool value) {
    if (value != _selected) {
      _selected = value;
      notifyListeners();
    }
  }

  @override
  set transform(CanvasItemTransform value) {
    if (value != _transform) {
      _transform = value;
      notifyListeners();
    }
  }

  @override
  @mustCallSuper
  void onAttached() {
    for (final child in children) {
      child.onAttached();
    }
  }

  @override
  @mustCallSuper
  void onDetached() {
    for (final child in children) {
      child.onDetached();
    }
  }

  @override
  Widget? buildOverlay(BuildContext context) => null;

  @override
  Clip get clipBehavior => _clip;

  @override
  set clipBehavior(Clip value) {
    if (value != _clip) {
      _clip = value;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'CanvasItemAdapter#$hashCode';
  }
}

class TextItem extends CanvasItemAdapter {
  final InlineSpan text;
  final TextDirection textDirection;

  TextItem({
    required this.text,
    super.selected,
    super.transform,
    this.textDirection = TextDirection.ltr,
    super.children = const [],
    super.clip = Clip.none,
  });

  @override
  void paint(Canvas canvas) {
    final textPainter = TextPainter(
      text: text,
      textDirection: textDirection,
    );
    textPainter.layout(
      minWidth: transform.size.width,
      maxWidth: transform.size.width,
    );
    textPainter.paint(canvas, Offset.zero);
  }

  void calculateDefaultSize() {
    final textPainter = TextPainter(
      text: text,
      textDirection: textDirection,
    );
    textPainter.layout();
    transform = transform.copyWith(
      size: Size(
        textPainter.width,
        textPainter.height,
      ),
    );
  }
}

class BoxItem extends CanvasItemAdapter {
  final Decoration decoration;

  BoxItem({
    required this.decoration,
    super.selected,
    super.transform,
    super.children = const [],
    super.clip = Clip.none,
  });

  late BoxPainter _painter;

  @override
  void paint(Canvas canvas) {
    _painter.paint(
      canvas,
      Offset.zero,
      ImageConfiguration(
        size: transform.size,
      ),
    );
    if (kDebugMode) {
      // paint the hash code
      final textPainter = TextPainter(
        text: TextSpan(
          text: hashCode.toString(),
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);
    }
  }

  @override
  void onAttached() {
    super.onAttached();
    _painter = decoration.createBoxPainter(() {
      notifyListeners();
    });
  }

  @override
  void onDetached() {
    super.onDetached();
    _painter.dispose();
  }

  @override
  String toString() {
    return 'BoxItem#$hashCode';
  }
}
