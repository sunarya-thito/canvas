abstract class Position {
  static const zero = AbsolutePosition(0);
  const Position();

  double compute(double size);
}

class AbsolutePosition extends Position {
  final double value;

  const AbsolutePosition(this.value);

  @override
  double compute(double size) {
    return value;
  }
}

class RelativePosition extends Position {
  final double value; // percentage of the parent size

  const RelativePosition(this.value);

  @override
  double compute(double size) {
    return size * value;
  }
}
