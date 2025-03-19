import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class NonOpaqueMetaData extends MetaData {
  const NonOpaqueMetaData({
    super.key,
    required this.opaque,
    super.child,
    super.behavior,
    super.metaData,
  });

  final bool opaque;

  @override
  RenderNonOpaqueMetaData createRenderObject(BuildContext context) {
    return RenderNonOpaqueMetaData(
        opaque: opaque, metaData: metaData, behavior: behavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderNonOpaqueMetaData renderObject) {
    renderObject
      ..opaque = opaque
      ..metaData = metaData
      ..behavior = behavior;
  }
}

class RenderNonOpaqueMetaData extends RenderMetaData {
  bool opaque;
  RenderNonOpaqueMetaData({
    super.metaData,
    super.behavior,
    required this.opaque,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!opaque) {
      super.hitTest(result, position: position);
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
