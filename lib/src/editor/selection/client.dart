import 'package:flutter/widgets.dart';

class SelectionClient {
  static const SelectionClient local = SelectionClient._();
  final BoxDecoration? decoration;

  const SelectionClient({
    required BoxDecoration this.decoration,
  });

  const SelectionClient._() : decoration = null;
}
