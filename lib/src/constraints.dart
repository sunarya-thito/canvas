import 'package:canvas/src/util.dart';
import 'package:flutter/rendering.dart';

import '../canvas.dart';

class FixedConstraints extends ItemConstraints with FixedTransformationMixin {
  @override
  final Offset offset;
  @override
  final Size size;
  @override
  final double rotation;
  @override
  final Offset scale;
  @override
  final Offset shear;

  const FixedConstraints({
    this.offset = Offset.zero,
    this.size = Size.zero,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
    this.shear = const Offset(0, 0),
  });

  @override
  String toString() {
    return 'copyWith(offset: $offset, size: $size, rotation: ${radToDeg(rotation)}, scale: $scale, shear: $shear)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FixedConstraints &&
        other.offset == offset &&
        other.size == size &&
        other.rotation == rotation &&
        other.scale == scale &&
        other.shear == shear;
  }

  @override
  int get hashCode {
    return Object.hash(offset, size, rotation, scale);
  }

  @override
  ItemConstraints transferToChild(ItemConstraints childLayout) {
    if (childLayout is FixedConstraints) {
      // return copyWith(
      //   offset: rotatePoint(offset - childLayout.offset, -childLayout.rotation),
      //   size: size,
      //   rotation: rotation - childLayout.rotation,
      //   scale: scale,
      //   shear: shear,
      // );
      Matrix4 transform = layoutTransform.toInverseMatrix4();
      var newOffset = transform.transformTranslation;
      var newRotation = transform.transformRotation;
      var newShear = transform.transformShear;
      var newScale = transform.transformScale;
      return copyWith(
        offset: newOffset,
        size: size,
        rotation: newRotation,
        scale: newScale,
        shear: newShear,
      );
    }
    return this;
  }

  LayoutTransform get layoutTransform {
    return LayoutTransform(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: scale,
      shear: shear,
    );
  }

  @override
  ItemConstraints transferToParent(ItemConstraints parentLayout) {
    if (parentLayout is FixedConstraints) {
      // return copyWith(
      //   offset:
      //       rotatePoint(offset, parentLayout.rotation) + parentLayout.offset,
      //   size: size,
      //   rotation: rotation + parentLayout.rotation,
      //   scale: scale,
      //   shear: shear,
      // );
      Matrix4 transform = layoutTransform.toMatrix4();
      var newOffset = transform.transformTranslation;
      var newRotation = transform.transformRotation;
      var newShear = transform.transformShear;
      var newScale = transform.transformScale;
      return copyWith(
        offset: newOffset,
        size: size,
        rotation: newRotation,
        scale: newScale,
        shear: newShear,
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

  FixedConstraints copyWith({
    Offset? offset,
    Size? size,
    double? rotation,
    Offset? scale,
    Offset? shear,
  }) {
    return FixedConstraints(
      offset: offset ?? this.offset,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      shear: shear ?? this.shear,
    );
  }

  @override
  ItemConstraints drag(CanvasItem item, Offset delta,
      {LayoutSnapping? snapping}) {
    var newOffset = offset + delta;
    if (snapping != null) {
      newOffset = snapping.config.snapToGrid(newOffset);
      snapping.newOffsetDelta = newOffset - offset;
    }
    var result = copyWith(offset: newOffset);
    if (snapping != null) {
      // TODO bring back snapping
      // List<SnappingPoint> points =
      //     result.getAllSnappingPoints(item, snapping.config.snappingToggle);
      // SnappingResult? snappingTarget = snapping.findSnappingTarget(points);
      // if (snappingTarget != null) {
      //   var delta = snappingTarget.delta;
      //   result = result.copyWith(offset: result.offset + delta);
      //   snapping.snappedPoint = snappingTarget;
      // } else {
      //   snapping.snappedPoint = null;
      // }
    }
    return result;
  }

  @override
  ItemConstraints rotate(CanvasItem item, double delta,
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
    return copyWith(
      offset: offset + offsetDelta,
      rotation: newRotation,
    );
  }

  @override
  ItemConstraints resizeBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
    Offset originalDelta = delta;
    Size newSize;
    ItemConstraints result;
    if (snapping != null) {
      newSize = Size(size.width, size.height + delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        snapped.width - size.width,
        snapped.height - size.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      newSize = Size(size.width, size.height + snappedSizeDelta.dy / scale.dy);
      result = copyWith(
        size: newSize,
      );
      // List<SnappingPoint> snappingPoints = getSnappingPoints(SnappingLocation.bottom);
    } else {
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height + delta.dy);
      result = copyWith(
        size: newSize,
      );
    }
    if (symmetric) {
      result = result.resizeTop(
          item, -(snapping?.newSizeDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeBottomLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    ItemConstraints result =
        resizeBottom(item, delta, snapping: snapping, location: location)
            .resizeLeft(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.resizeTopRight(item, -(snapping?.newSizeDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeBottomRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    ItemConstraints result =
        resizeBottom(item, delta, snapping: snapping, location: location)
            .resizeRight(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.resizeTopLeft(item, -(snapping?.newSizeDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
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
      newOffset =
          offset + rotatePoint(snappedSizeDelta, rotation).shear(shear.onlyY());
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation).shear(shear.onlyY());
      delta = delta.divideBy(scale);
      newOffset = offset + rotatedDelta;
      newSize = Size(size.width - delta.dx, size.height);
    }
    ItemConstraints result = copyWith(
      offset: newOffset,
      size: newSize,
    );
    if (symmetric) {
      result = result.resizeRight(
          item, -(snapping?.newSizeDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
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
    ItemConstraints result = copyWith(
      offset: offset,
      size: newSize,
      rotation: rotation,
      scale: scale,
    );
    if (symmetric) {
      result = result.resizeLeft(
          item, -(snapping?.newSizeDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
    Offset originalDelta = delta;
    delta = delta.onlyY();
    Size newSize;
    Offset newOffset;
    if (snapping != null) {
      newSize = Size(size.width, size.height - delta.dy);
      var snapped = snapping.config.snapToGridSize(newSize);
      var snappedSizeDelta = Offset(
        size.width - snapped.width,
        size.height - snapped.height,
      );
      snapping.newSizeDeltaY = snappedSizeDelta.dy;
      Offset sizeDelta = Offset(
        snappedSizeDelta.dx,
        snappedSizeDelta.dy,
      ).divideBy(scale);
      newSize = Size(size.width, size.height - sizeDelta.dy);
      newOffset =
          offset + rotatePoint(snappedSizeDelta, rotation).shear(shear.onlyX());
    } else {
      Offset rotatedDelta = rotatePoint(delta, rotation).shear(shear.onlyX());
      delta = delta.divideBy(scale);
      newSize = Size(size.width, size.height - delta.dy);
      newOffset = offset + rotatedDelta;
    }
    ItemConstraints result = copyWith(
      offset: newOffset,
      size: newSize,
    );
    if (symmetric) {
      result = result.resizeBottom(
          item, -(snapping?.newSizeDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeTopLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    ItemConstraints result =
        resizeTop(item, delta, snapping: snapping, location: location)
            .resizeLeft(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.resizeBottomRight(
          item, -(snapping?.newSizeDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints resizeTopRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    ItemConstraints result =
        resizeTop(item, delta, snapping: snapping, location: location)
            .resizeRight(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.resizeBottomLeft(item, -(snapping?.newSizeDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
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
    ItemConstraints result = copyWith(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleTop(
          item, -(snapping?.newScaleDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleBottomLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(delta.dx, -delta.dy), aspectRatio);
      delta = Offset(proportional.dx, -proportional.dy);
    }
    ItemConstraints result =
        rescaleBottom(item, delta, snapping: snapping, location: location)
            .rescaleLeft(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.rescaleTopRight(item, -(snapping?.newScaleDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleBottomRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    if (proportional) {
      delta = -proportionalDelta(-delta, aspectRatio);
    }
    ItemConstraints result =
        rescaleBottom(item, delta, snapping: snapping, location: location)
            .rescaleRight(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.rescaleTopLeft(item, -(snapping?.newScaleDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
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
    ItemConstraints result = copyWith(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleRight(
          item, -(snapping?.newScaleDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
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
    ItemConstraints result = copyWith(
      offset: offset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleLeft(
          item, -(snapping?.newScaleDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
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
    ItemConstraints result = copyWith(
      offset: newOffset,
      size: size,
      rotation: rotation,
      scale: newScale,
    );
    if (symmetric) {
      result = result.rescaleBottom(
          item, -(snapping?.newScaleDelta ?? originalDelta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleTopLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    if (proportional) {
      delta = proportionalDelta(delta, aspectRatio);
    }
    ItemConstraints result =
        rescaleTop(item, delta, snapping: snapping, location: location)
            .rescaleLeft(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.rescaleBottomRight(
          item, -(snapping?.newScaleDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  ItemConstraints rescaleTopRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    if (proportional) {
      var proportional =
          proportionalDelta(Offset(-delta.dx, delta.dy), aspectRatio);
      delta = Offset(-proportional.dx, proportional.dy);
    }
    ItemConstraints result =
        rescaleTop(item, delta, snapping: snapping, location: location)
            .rescaleRight(item, delta, snapping: snapping, location: location);
    if (symmetric) {
      result = result.rescaleBottomLeft(
          item, -(snapping?.newScaleDelta ?? delta),
          location: null);
    }
    return result;
  }

  @override
  LayoutTransform constrain(CanvasItem item, BoxConstraints constraints) {
    return layoutTransform;
  }
}

class FlexibleConstraints extends ItemConstraints {
  final SizeConstraint width;
  final SizeConstraint height;
  final double rotation;

  const FlexibleConstraints({
    this.width = const SizeConstraint.fixed(0),
    this.height = const SizeConstraint.fixed(0),
    this.rotation = 0,
  });

  SizeConstraint getConstraint(Axis axis) {
    return axis == Axis.horizontal ? width : height;
  }

  @override
  bool get constrainedByParent => true;

  @override
  LayoutTransform constrain(CanvasItem item, BoxConstraints constraints) {
    assert(item.parent is FlexLayout, 'Parent must be a FlexLayout');
    throw Exception('FlexibleConstraints constrain is performed by FlexLayout');
  }

  @override
  ItemConstraints drag(CanvasItem item, Offset delta,
      {LayoutSnapping? snapping}) {
    // TODO: implement drag
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
    // TODO: implement rescaleBottom
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottomLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    // TODO: implement rescaleBottomLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottomRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    // TODO: implement rescaleBottomRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
    // TODO: implement rescaleLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
    // TODO: implement rescaleRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
    // TODO: implement rescaleTop
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTopLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    // TODO: implement rescaleTopLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTopRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    // TODO: implement rescaleTopRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
    // TODO: implement resizeBottom
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottomLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    // TODO: implement resizeBottomLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottomRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    // TODO: implement resizeBottomRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
    // TODO: implement resizeLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
    // TODO: implement resizeRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
    // TODO: implement resizeTop
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTopLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    // TODO: implement resizeTopLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTopRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    // TODO: implement resizeTopRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rotate(CanvasItem item, double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping}) {
    // TODO: implement rotate
    throw UnimplementedError();
  }

  @override
  ItemConstraints transferToChild(ItemConstraints childLayout) {
    // TODO: implement transferToChild
    throw UnimplementedError();
  }

  @override
  ItemConstraints transferToParent(ItemConstraints parentLayout) {
    // TODO: implement transferToParent
    throw UnimplementedError();
  }
}

abstract class SizeConstraint {
  const SizeConstraint();

  const factory SizeConstraint.fill([double flex]) = _FillConstraint.fill;
  const factory SizeConstraint.fillLoose(double value, [double flex]) =
      _FillConstraint.loose;
  const factory SizeConstraint.fillTight(double value, [double flex]) =
      _FillConstraint.tight;
  const factory SizeConstraint.fillBoxed(double min, double max,
      [double flex]) = _FillConstraint;
  const factory SizeConstraint.fixed(double value) = _FixedConstraint.fixed;
  const factory SizeConstraint.boxed(double min, double max) = _FixedConstraint;
  const factory SizeConstraint.loose(double value) = _FixedConstraint.loose;
  const factory SizeConstraint.tight(double value) = _FixedConstraint.tight;
  const factory SizeConstraint.fit() = _FitConstraint.fit;
  const factory SizeConstraint.looseFit(double value) = _FitConstraint.loose;
  const factory SizeConstraint.tightFit(double value) = _FitConstraint.tight;
  const factory SizeConstraint.fitBoxed(double min, double max) =
      _FitConstraint;
  const factory SizeConstraint.scaledBoxed(
      double scale, double min, double max) = _ScaledFixedConstraint;
  const factory SizeConstraint.scaledLoose(double scale, double value) =
      _ScaledFixedConstraint.loose;
  const factory SizeConstraint.scaledTight(double scale, double value) =
      _ScaledFixedConstraint.tight;
  const factory SizeConstraint.scaled(double scale, double value) =
      _ScaledFixedConstraint.fixed;

  FlexLayoutPlanInfo plan(CanvasItem item, Axis direction);
  FlexConstrainResult constrain(FlexLayoutPlanInfo plan, CanvasItem item,
      Axis direction, FlexLayoutInfo info);
}

class _FillConstraint extends _FixedConstraint {
  final double flex;

  const _FillConstraint(super.min, super.max, [this.flex = 1]);
  const _FillConstraint.fill([this.flex = 1]) : super(0, double.infinity);
  const _FillConstraint.loose(double value, [this.flex = 1]) : super(0, value);
  const _FillConstraint.tight(double value, [this.flex = 1])
      : super(value, double.infinity);

  @override
  FlexLayoutPlanInfo plan(CanvasItem item, Axis direction) {
    return FlexLayoutPlanInfo(
      flexSize: flex,
    );
  }

  @override
  FlexConstrainResult constrain(FlexLayoutPlanInfo plan, CanvasItem item,
      Axis direction, FlexLayoutInfo info) {
    var allocatedSpace = info.allocatedSpace;
    var flexSize = info.flexSize;
    if (flexSize == 0) {
      return FlexConstrainResult(
        size: 0,
      );
    }
    var flexSpace = allocatedSpace * flex / flexSize;
    var clampedSize = flexSpace.clamp(min, max);
    return FlexConstrainResult(
      size: clampedSize,
    );
  }
}

class _FixedConstraint extends SizeConstraint {
  final double min;
  final double max;

  const _FixedConstraint(this.min, this.max);

  const _FixedConstraint.fixed(double value)
      : min = value,
        max = value;
  const _FixedConstraint.loose(double value)
      : min = 0,
        max = value;
  const _FixedConstraint.tight(double value)
      : min = value,
        max = double.infinity;

  @override
  FlexLayoutPlanInfo plan(CanvasItem item, Axis direction) {
    return FlexLayoutPlanInfo(
      fixedSize: min,
    );
  }

  @override
  FlexConstrainResult constrain(FlexLayoutPlanInfo plan, CanvasItem item,
      Axis direction, FlexLayoutInfo info) {
    return FlexConstrainResult(
      size: min,
    );
  }
}

class _ScaledFixedConstraint extends _FixedConstraint {
  final double scale;

  const _ScaledFixedConstraint(this.scale, super.min, super.max);
  const _ScaledFixedConstraint.fixed(this.scale, double value)
      : super(value, value);
  const _ScaledFixedConstraint.loose(this.scale, double value)
      : super(0, value);
  const _ScaledFixedConstraint.tight(this.scale, double value)
      : super(value, double.infinity);

  @override
  FlexLayoutPlanInfo plan(CanvasItem item, Axis direction) {
    return FlexLayoutPlanInfo(
      fixedSize: min * scale,
    );
  }

  @override
  FlexConstrainResult constrain(FlexLayoutPlanInfo plan, CanvasItem item,
      Axis direction, FlexLayoutInfo info) {
    return FlexConstrainResult(
      size: min,
      scale: scale,
    );
  }
}

class _FitConstraint extends _FixedConstraint {
  const _FitConstraint(super.min, super.max);
  const _FitConstraint.fit() : super(0, double.infinity);
  const _FitConstraint.loose(double value) : super(0, value);
  const _FitConstraint.tight(double value) : super(value, double.infinity);

  @override
  FlexLayoutPlanInfo plan(CanvasItem item, Axis direction) {
    var intrinsicSize = direction == Axis.horizontal
        ? item.layout.computeIntrinsicWidth(item)
        : item.layout.computeIntrinsicHeight(item);
    return FlexLayoutPlanInfo(
      fixedSize: intrinsicSize.clamp(min, max),
    );
  }

  @override
  FlexConstrainResult constrain(FlexLayoutPlanInfo plan, CanvasItem item,
      Axis direction, FlexLayoutInfo info) {
    return FlexConstrainResult(
      size: plan.fixedSize,
    );
  }
}

class AnchoredConstraints extends ItemConstraints {
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;
  final double? width;
  final double? height;
  @override
  final double rotation;
  final Offset scale;
  final double? horizontal; // 0.0 - 1.0
  final double? vertical; // 0.0 - 1.0

  const AnchoredConstraints.topLeft({
    this.top,
    this.left,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : bottom = null,
        right = null,
        horizontal = null,
        vertical = null;

  const AnchoredConstraints.topRight({
    this.top,
    this.right,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : bottom = null,
        left = null,
        horizontal = null,
        vertical = null;

  const AnchoredConstraints.bottomLeft({
    this.bottom,
    this.left,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        right = null,
        horizontal = null,
        vertical = null;

  const AnchoredConstraints.bottomRight({
    this.bottom,
    this.right,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        left = null,
        horizontal = null,
        vertical = null;

  const AnchoredConstraints.top({
    this.top,
    this.horizontal,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : bottom = null,
        left = null,
        right = null,
        vertical = null;

  const AnchoredConstraints.bottom({
    this.bottom,
    this.horizontal,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        left = null,
        right = null,
        vertical = null;

  const AnchoredConstraints.left({
    this.left,
    this.vertical,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        right = null,
        bottom = null,
        horizontal = null;

  const AnchoredConstraints.right({
    this.right,
    this.vertical,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        left = null,
        bottom = null,
        horizontal = null;

  const AnchoredConstraints.aligned({
    this.horizontal,
    this.vertical,
    this.width,
    this.height,
    this.rotation = 0,
    this.scale = const Offset(1, 1),
  })  : top = null,
        left = null,
        right = null,
        bottom = null;

  @override
  LayoutTransform constrain(CanvasItem item, BoxConstraints constraints) {
    // TODO: implement constrain
    throw UnimplementedError();
  }

  @override
  ItemConstraints drag(CanvasItem item, Offset delta,
      {LayoutSnapping? snapping}) {
    // TODO: implement drag
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
    // TODO: implement rescaleBottom
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottomLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    // TODO: implement rescaleBottomLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleBottomRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    // TODO: implement rescaleBottomRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
    // TODO: implement rescaleLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
    // TODO: implement rescaleRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
    // TODO: implement rescaleTop
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTopLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    // TODO: implement rescaleTopLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints rescaleTopRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      bool proportional = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    // TODO: implement rescaleTopRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottom(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottom}) {
    // TODO: implement resizeBottom
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottomLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomLeft}) {
    // TODO: implement resizeBottomLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeBottomRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.bottomRight}) {
    // TODO: implement resizeBottomRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeLeft(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.left}) {
    // TODO: implement resizeLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeRight(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.right}) {
    // TODO: implement resizeRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTop(CanvasItem item, Offset delta,
      {bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.top}) {
    // TODO: implement resizeTop
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTopLeft(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topLeft}) {
    // TODO: implement resizeTopLeft
    throw UnimplementedError();
  }

  @override
  ItemConstraints resizeTopRight(CanvasItem item, Offset delta,
      {bool proportional = false,
      bool symmetric = false,
      LayoutSnapping? snapping,
      SnappingLocation? location = SnappingLocation.topRight}) {
    // TODO: implement resizeTopRight
    throw UnimplementedError();
  }

  @override
  ItemConstraints rotate(CanvasItem item, double delta,
      {Alignment alignment = Alignment.center, LayoutSnapping? snapping}) {
    // TODO: implement rotate
    throw UnimplementedError();
  }

  @override
  ItemConstraints transferToChild(ItemConstraints childLayout) {
    // TODO: implement transferToChild
    throw UnimplementedError();
  }

  @override
  ItemConstraints transferToParent(ItemConstraints parentLayout) {
    // TODO: implement transferToParent
    throw UnimplementedError();
  }
}
