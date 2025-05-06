import 'package:canvas/canvas.dart';
import 'package:flutter/rendering.dart';

typedef CanvasHitTest = bool Function(
    CanvasHitTestResult result, Offset position);

typedef CanvasHitTestPath = void Function(
    CanvasHitTestResult result, Path path);

class CanvasHitTestResult extends HitTestResult {
  CanvasHitTestResult() : super();

  @override
  Iterable<HitTestEntry<CanvasItemState>> get path =>
      super.path.cast<HitTestEntry<CanvasItemState>>();

  bool addWithRawTransform({
    required Matrix4? transform,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    final Offset transformedPosition = transform == null
        ? position
        : MatrixUtils.transformPoint(transform, position);
    if (transform != null) {
      pushTransform(transform);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (transform != null) {
      popTransform();
    }
    return isHit;
  }

  bool addWithPaintTransform({
    required Matrix4? transform,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return false;
      }
    }
    return addWithRawTransform(
        transform: transform, position: position, hitTest: hitTest);
  }

  bool addWithPaintOffset({
    required Offset? offset,
    required Offset position,
    required CanvasHitTest hitTest,
  }) {
    final Offset transformedPosition =
        offset == null ? position : position - offset;
    if (offset != null) {
      pushOffset(-offset);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (offset != null) {
      popTransform();
    }
    return isHit;
  }

  void addWithRawTransformPath({
    required Matrix4? transform,
    required Path path,
    required CanvasHitTestPath hitTest,
  }) {
    final Path transformedPath =
        transform == null ? path : path.transform(transform.storage);
    if (transform != null) {
      pushTransform(transform);
    }
    hitTest(this, transformedPath);
    if (transform != null) {
      popTransform();
    }
  }

  void addWithPaintTransformPath({
    required Matrix4? transform,
    required Path path,
    required CanvasHitTestPath hitTest,
  }) {
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return;
      }
    }
    addWithRawTransformPath(transform: transform, path: path, hitTest: hitTest);
  }
}

class CanvasHitTestEntry extends HitTestEntry<CanvasItemState> {
  final Offset localPosition;
  CanvasHitTestEntry(super.target, this.localPosition);
  @override
  String toString() {
    return 'CanvasHitTestEntry(target: $target, localPosition: $localPosition)';
  }
}

enum PathOverlap {
  none,
  partial,
  full,
}

class CanvasPathHitTestEntry extends HitTestEntry<CanvasItemState> {
  final PathOverlap overlap;

  CanvasPathHitTestEntry(super.target, this.overlap);

  @override
  String toString() {
    return 'CanvasPathHitTestEntry(target: $target, overlap: $overlap)';
  }
}
