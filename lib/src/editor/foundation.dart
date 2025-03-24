import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class CanvasEditorTransform {
  final Offset offset;
  final double zoom;

  const CanvasEditorTransform({
    this.offset = Offset.zero,
    this.zoom = 1.0,
  });

  CanvasEditorTransform copyWith({
    Offset? offset,
    double? zoom,
  }) {
    return CanvasEditorTransform(
      offset: offset ?? this.offset,
      zoom: zoom ?? this.zoom,
    );
  }

  CanvasEditorTransform drag(Offset delta) {
    return copyWith(offset: offset + delta);
  }

  CanvasEditorTransform zoomAt(Offset position,
      {double delta = 0.1, double? maxZoom, double? minZoom}) {
    delta = delta * zoom;
    var currentZoom = zoom;
    if (maxZoom != null) {
      if (currentZoom + delta > maxZoom) {
        delta = maxZoom - currentZoom;
      }
    }
    if (minZoom != null) {
      if (currentZoom + delta < minZoom) {
        delta = minZoom - currentZoom;
      }
    }
    return copyWith(
      offset: offset - (position - offset) * delta / zoom,
      zoom: zoom + delta,
    );
  }

  @override
  String toString() {
    return 'CanvasEditorTransform{offset: $offset, zoom: $zoom}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasEditorTransform &&
        other.offset == offset &&
        other.zoom == zoom;
  }

  @override
  int get hashCode {
    return Object.hash(offset, zoom);
  }
}

class CanvasEditorController extends ValueNotifier<CanvasEditorTransform> {
  CanvasEditorController({
    CanvasEditorTransform? value,
  }) : super(value ?? const CanvasEditorTransform());
}
