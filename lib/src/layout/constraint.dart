abstract class SizeConstraint {
  const SizeConstraint();
  static const SizeConstraint intrinsic = IntrinsicSizeConstraint();
  static ConstrainedSizeConstraint fixed(double size) =>
      FixedSizeConstraint(size);
  static SizeConstraint flex(double flex) => FlexSizeConstraint(flex: flex);
  static ConstrainedSizeConstraint relative(double size) =>
      RelativeSizeConstraint(size: size);
  static SizeConstraint unconstrained = UnconstrainedSizeConstraint();
  static SizeConstraint aspectRatio(double aspectRatio) =>
      AspectRatioSizeConstraint(aspectRatio);
}

abstract class ConstrainedSizeConstraint extends SizeConstraint {
  const ConstrainedSizeConstraint();
}

class IntrinsicSizeConstraint extends SizeConstraint {
  const IntrinsicSizeConstraint();
}

class AspectRatioSizeConstraint extends ConstrainedSizeConstraint {
  final double aspectRatio;

  const AspectRatioSizeConstraint(this.aspectRatio);
}

class FixedSizeConstraint extends ConstrainedSizeConstraint {
  final double size;

  const FixedSizeConstraint(this.size);
}

class FlexSizeConstraint extends SizeConstraint {
  final double flex;

  const FlexSizeConstraint({
    this.flex = 1,
  });
}

class UnconstrainedSizeConstraint extends SizeConstraint {
  const UnconstrainedSizeConstraint();
}

class RelativeSizeConstraint extends ConstrainedSizeConstraint {
  final double size; // percentage of the parent size

  const RelativeSizeConstraint({
    required this.size,
  });
}
