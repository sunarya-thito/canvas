abstract class Position {
  static const zero = AbsolutePosition(0);
  const factory Position.absolute(double value) = AbsolutePosition;
  const factory Position.fractional(double value) = FractionalPosition;
  const Position();

  double compute(double size);
  Position shift(double delta, double size);
}

class AbsolutePosition extends Position {
  final double value;

  const AbsolutePosition(this.value);

  @override
  double compute(double size) {
    return value;
  }

  @override
  Position shift(double delta, double size) {
    return AbsolutePosition(value + delta);
  }

  @override
  String toString() {
    return 'AbsolutePosition{value: $value}';
  }
}

class FractionalPosition extends Position {
  final double value; // percentage of the parent size

  const FractionalPosition(this.value);

  @override
  double compute(double size) {
    return size * value;
  }

  @override
  Position shift(double delta, double size) {
    return FractionalPosition(value + delta / size);
  }

  @override
  String toString() {
    return 'FractionalPosition{value: $value}';
  }
}
