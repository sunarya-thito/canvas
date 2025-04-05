import 'dart:ui';

String optimalDoubleString(double d) {
  // do not use d.toInt() == d method,
  String s = d.toStringAsFixed(2);
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  }
  return s;
}

extension SizeExtension on Size {
  Offset get asOffset => Offset(width, height);
}

extension OffsetExtension on Offset {
  Size get asSize => Size(dx, dy);
}
