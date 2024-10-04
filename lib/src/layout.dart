import 'package:canvas/src/util.dart';
import 'package:flutter/painting.dart';

import '../canvas.dart';

class AbsoluteLayout extends Layout {
  final Offset offset;
  final Size size;
  final double rotation;
  final Offset scale;

  const AbsoluteLayout({
    this.offset = Offset.zero,
    this.size = Size.zero,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  });

  @override
  String toString() {
    return 'AbsoluteLayout(offset: $offset, size: $size, rotation: ${radToDeg(rotation)}, scale: $scale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AbsoluteLayout &&
        other.offset == offset &&
        other.size == size &&
        other.rotation == rotation &&
        other.scale == scale;
  }

  @override
  int get hashCode {
    return Object.hash(offset, size, rotation, scale);
  }

  @override
  Layout transferToChild(Layout childLayout) {
    if (childLayout is AbsoluteLayout) {
      return AbsoluteLayout(
        offset: rotatePoint(offset - childLayout.offset, -childLayout.rotation),
        size: size,
        rotation: rotation - childLayout.rotation,
        scale: scale,
      );
    }
    return this;
  }

  @override
  Layout transferToParent(Layout parentLayout) {
    if (parentLayout is AbsoluteLayout) {
      return AbsoluteLayout(
        offset:
            rotatePoint(offset, parentLayout.rotation) + parentLayout.offset,
        size: size,
        rotation: rotation + parentLayout.rotation,
        scale: scale,
      );
    }
    return this;
  }

  Size get scaledSize => Size(size.width * scale.dx, size.height * scale.dy);

  double get aspectRatio {
    Size scaledSize = this.scaledSize;
    if (scaledSize.height == 0) {
      if (scaledSize.width == 0) {
        return 1;
      }
      return 0;
    }
    return scaledSize.width / scaledSize.height;
  }

  @override
  void performLayout(CanvasItem item, [CanvasItem? parent]) {
    if (parent != null && parent.layout.shouldHandleChildLayout) {
      parent.layoutListenable.value.performLayout(parent);
      return;
    }
    performSelfLayout(item);
  }

  @override
  void performSelfLayout(CanvasItem item) {
    item.transform = LayoutTransform(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  Layout drag(Offset delta, {LayoutSnapping? snapping}) {
    var newOffset = offset + delta;
    if (snapping != null) {
      newOffset = snapping.config.snapToGrid(newOffset);
      snapping.newOffsetDelta = newOffset - offset;
    }
    return AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  Layout rotate(double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping}) {
    double newRotation = rotation + delta;
    if (snapping != null) {
      var oldNewRotation = newRotation;
      newRotation = snapping.config.snapAngle(newRotation);
      snapping.newRotationDelta = delta - (oldNewRotation - newRotation);
    }
    Size scaledSize = this.scaledSize;
    Offset before = rotatePoint(-alignment.alongSize(scaledSize), rotation);
    Offset after = rotatePoint(-alignment.alongSize(scaledSize), newRotation);
    Offset offsetDelta = after - before;
    return AbsoluteLayout(
      offset: offset + offsetDelta,
      size: size,
      rotation: newRotation,
      scale: scale,
    );
  }

  @override
  Layout resizeBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width, size.height + delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        snapped.width - size.width,
        snapped.height - size.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      newSize = Size(size.width, size.height + snappedSizeDelta.dy / scale.dy);
    } else {
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height + delta.dy);
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeTop(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeBottomLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopRight(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeBottomRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    Layout result = resizeBottom(delta, snapping: snapping)
        .resizeRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeTopLeft(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();

    Offset newOffset;
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width - delta.dx, size.height);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        size.width - snapped.width,
        delta.dy,
      );
      snapping.newSizeDeltaX = snappedSizeDelta.dx;
      newSize = Size(size.width - snappedSizeDelta.dx / scale.dx, size.height);
      newOffset = offset + rotatePoint(snappedSizeDelta, rotation);
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation);
      delta = delta.divideBy(scale);
      newOffset = offset + rotatedDelta;
      newSize = Size(size.width - delta.dx, size.height);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeRight(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Size newSize;
    if (snapping != null) {
      newSize = Size(size.width + delta.dx, size.height);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        snapped.width - size.width,
        snapped.height - size.height,
      );
      snapping.newSizeDeltaX = snappedSizeDelta.dx;
      newSize = Size(size.width + snappedSizeDelta.dx / scale.dx, size.height);
    } else {
      delta = delta.divideBy(scale);
      newSize = Size(size.width + delta.dx, size.height);
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeLeft(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Size newSize;
    Offset newOffset;
    if (snapping != null) {
      newSize = Size(size.width, size.height - delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        0,
        size.height - snapped.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      newSize = Size(size.width, size.height - snappedSizeDelta.dy / scale.dy);
      newOffset = offset + rotatePoint(snappedSizeDelta, rotation);
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation);
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height - delta.dy);
      newOffset = offset + rotatedDelta;
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeBottom(-(snapping?.newSizeDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout resizeTopLeft(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = resizeTop(delta, snapping: snapping)
        .resizeLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeBottomRight(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout resizeTopRight(Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    Layout result = resizeTop(delta, snapping: snapping)
        .resizeRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.resizeBottomLeft(-(snapping?.newSizeDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleBottom(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    var newScale = Offset(scale.dx, scale.dy + delta.dy / size.height);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      newScale = Offset(scale.dx, snappedSize.height / size.height);
      snapping.newScaleDeltaY = snappedSize.height - oldScaledSize.height;
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleTop(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleBottomLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    Layout result = rescaleBottom(delta, snapping: snapping)
        .rescaleLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleTopRight(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleBottomRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    Layout result = rescaleBottom(delta, snapping: snapping)
        .rescaleRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleTopLeft(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleLeft(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    var newOffset = offset + rotatedDelta;
    var newScale = Offset(scale.dx - delta.dx / size.width, scale.dy);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      var snappedSizeDelta = Offset(
        snappedSize.width - oldScaledSize.width,
        snappedSize.height - oldScaledSize.height,
      );
      snappedSizeDelta = snapping.config.snapToGrid(snappedSizeDelta);
      var newScaleDelta = Offset(
        snappedSizeDelta.dx / size.width,
        snappedSizeDelta.dy / size.height,
      );
      snapping.newScaleDeltaX = -snappedSizeDelta.dx;
      newScale = scale + newScaleDelta;
      newOffset = offset - rotatePoint(snappedSizeDelta, rotation);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleRight(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleRight(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyX();
    var newScale = Offset(scale.dx + delta.dx / size.width, scale.dy);
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      newScale = Offset(snappedSize.width / size.width, scale.dy);
      snapping.newScaleDeltaX = snappedSize.width - oldScaledSize.width;
    }
    Layout result = AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleLeft(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleTop(Offset delta,
      {bool symmetric = false, LayoutSnapping? snapping}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    var newScale = Offset(scale.dx, scale.dy - delta.dy / size.height);
    var newOffset = offset + rotatedDelta;
    if (snapping != null) {
      var oldScaledSize = scaledSize;
      var newScaledSize =
          Size(size.width * newScale.dx, size.height * newScale.dy);
      var snappedSize = snapping.config.snapToGridSize(newScaledSize);
      var snappedSizeDelta = Offset(
        snappedSize.width - oldScaledSize.width,
        snappedSize.height - oldScaledSize.height,
      );
      snappedSizeDelta = snapping.config.snapToGrid(snappedSizeDelta);
      var newScaleDelta = Offset(
        snappedSizeDelta.dx / size.width,
        snappedSizeDelta.dy / size.height,
      );
      snapping.newScaleDeltaY = -snappedSizeDelta.dy;
      newScale = scale + newScaleDelta;
      newOffset = offset - rotatePoint(snappedSizeDelta, rotation);
    }
    Layout result = AbsoluteLayout(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result =
          result.rescaleBottom(-(snapping?.newScaleDelta ?? originalDelta));
    }
    return result;
  }

  @override
  Layout rescaleTopLeft(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    Layout result = rescaleTop(delta, snapping: snapping)
        .rescaleLeft(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleBottomRight(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  Layout rescaleTopRight(Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    Layout result = rescaleTop(delta, snapping: snapping)
        .rescaleRight(delta, snapping: snapping);
    if (symmetric) {
      result = result.rescaleBottomLeft(-(snapping?.newScaleDelta ?? delta));
    }
    return result;
  }

  @override
  bool get shouldHandleChildLayout => false;

  @override
  LayoutChanges createChanges() {
    return AbsoluteLayoutChanges(this);
  }
}

class AbsoluteLayoutChanges extends LayoutChanges {
  double offsetDeltaX = 0;
  double offsetDeltaY = 0;
  double sizeDeltaX = 0;
  double sizeDeltaY = 0;
  double rotationDelta = 0;
  double scaleDeltaX = 0;
  double scaleDeltaY = 0;

  final AbsoluteLayout layout;

  AbsoluteLayoutChanges(this.layout);

  @override
  Layout apply(Layout layout) {
    if (layout is! AbsoluteLayout) {
      return layout;
    }
    Offset offset = layout.offset;
    Size size = layout.size;
    double rotation = layout.rotation;
    Offset scale = layout.scale;
    return AbsoluteLayout(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: scale,
    );
  }

  @override
  void reset() {
    offsetDeltaX = 0;
    offsetDeltaY = 0;
    sizeDeltaX = 0;
    sizeDeltaY = 0;
    rotationDelta = 0;
    scaleDeltaX = 0;
    scaleDeltaY = 0;
  }

  @override
  void snap(LayoutSnapping snapping) {
    Offset newOffset = snapping.config.snapToGrid(layout.offset);
    offsetDeltaX = newOffset.dx - layout.offset.dx;
    offsetDeltaY = newOffset.dy - layout.offset.dy;
    Size newSize = snapping.config.snapToGridSize(layout.size);
    sizeDeltaX = newSize.width - layout.size.width;
    sizeDeltaY = newSize.height - layout.size.height;
    double newRotation = snapping.config.snapAngle(layout.rotation);
    rotationDelta = newRotation - layout.rotation;
    Offset newScale = Offset(
      layout.scale.dx + scaleDeltaX,
      layout.scale.dy + scaleDeltaY,
    );
    Size oldScaledSize = layout.scaledSize;
    Size newScaledSize = Size(
      newSize.width * newScale.dx,
      newSize.height * newScale.dy,
    );
    Size snappedSize = snapping.config.snapToGridSize(newScaledSize);
    scaleDeltaX = (snappedSize.width - oldScaledSize.width) / layout.size.width;
    scaleDeltaY =
        (snappedSize.height - oldScaledSize.height) / layout.size.height;
  }

  @override
  double get aspectRatio => layout.aspectRatio;

  @override
  void drag(Offset delta) {
    offsetDeltaX += delta.dx;
    offsetDeltaY += delta.dy;
  }

  @override
  void handleRescaleBottom(Offset delta) {
    delta = delta.onlyY();
    scaleDeltaY += delta.dy / size.height;
  }

  @override
  void handleRescaleLeft(Offset delta) {
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    offsetDeltaX += rotatedDelta.dx;
    offsetDeltaY += rotatedDelta.dy;
    scaleDeltaX -= delta.dx / size.width;
  }

  @override
  void handleRescaleRight(Offset delta) {
    delta = delta.onlyX();
    scaleDeltaX += delta.dx / size.width;
  }

  @override
  void handleRescaleTop(Offset delta) {
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    offsetDeltaX += rotatedDelta.dx;
    offsetDeltaY += rotatedDelta.dy;
    scaleDeltaY -= delta.dy / size.height;
  }

  @override
  void handleResizeBottom(Offset delta) {
    delta = delta.divideBy(scale);
    sizeDeltaY += delta.dy;
  }

  @override
  void handleResizeLeft(Offset delta) {
    delta = delta.onlyX();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    delta = delta.divideBy(scale);
    offsetDeltaX += rotatedDelta.dx;
    offsetDeltaY += rotatedDelta.dy;
    sizeDeltaX -= delta.dx;
  }

  @override
  void handleResizeRight(Offset delta) {
    delta = delta.onlyX();
    delta = delta.divideBy(scale);
    sizeDeltaX += delta.dx;
  }

  @override
  void handleResizeTop(Offset delta) {
    delta = delta.onlyY();
    Offset rotatedDelta = rotatePoint(delta, rotation);
    delta = delta.divideBy(scale);
    offsetDeltaX += rotatedDelta.dx;
    offsetDeltaY += rotatedDelta.dy;
    sizeDeltaY -= delta.dy;
  }

  @override
  void handleRotate(double delta) {
    rotationDelta += delta;
  }

  @override
  double get rotation => layout.rotation + rotationDelta;

  @override
  Size get scaledSize {
    Size size = this.size;
    Offset scale = this.scale;
    return Size(size.width * scale.dx, size.height * scale.dy);
  }

  @override
  Offset get offset => layout.offset + Offset(offsetDeltaX, offsetDeltaY);

  @override
  Offset get scale => layout.scale + Offset(scaleDeltaX, scaleDeltaY);

  @override
  Size get size {
    Size size = layout.size;
    return Size(size.width + sizeDeltaX, size.height + sizeDeltaY);
  }
}
