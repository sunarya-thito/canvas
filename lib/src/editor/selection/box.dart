import 'package:canvas/src/editor/selection/client.dart';
import 'package:flutter/widgets.dart';

class SelectionBox {
  final SelectionClient client;
  final ValueNotifier<Offset> start;
  final ValueNotifier<Offset> end;

  const SelectionBox({
    required this.client,
    required this.start,
    required this.end,
  });

  SelectionBox.local({
    Offset start = Offset.zero,
  })  : client = SelectionClient.local,
        start = ValueNotifier(start),
        end = ValueNotifier(start);

  Rect get rect {
    return Rect.fromPoints(start.value, end.value);
  }
}
