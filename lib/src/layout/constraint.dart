abstract class SizeConstraint {
  const SizeConstraint();
}

abstract class ConstrainedSizeConstraint extends SizeConstraint {
  const ConstrainedSizeConstraint();

  double compute(double size);
}

class IntrinsicSizeConstraint extends SizeConstraint {
  const IntrinsicSizeConstraint();
}

class FixedSizeConstraint extends ConstrainedSizeConstraint {
  final double size;

  const FixedSizeConstraint(this.size);

  @override
  double compute(double size) {
    return this.size;
  }
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

  @override
  double compute(double parentSize) {
    return size * parentSize;
  }
}
