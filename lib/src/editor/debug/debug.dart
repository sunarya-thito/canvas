import 'package:canvas/src/widget_util.dart';
import 'package:data_widget/data_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// final Map<Object, Offset> _debugPoints =
final MutableNotifier<Map<Object, _DebugPoint>> _debugPoints =
    MutableNotifier({});

extension ListEqualifierExtension<T> on Iterable<T> {
  ListEqualifier<T> get equalifiable => ListEqualifier(toList());
  SetEqualifier<T> get setEqualifiable => SetEqualifier(toSet());
}

class ListEqualifier<T> {
  final List<T> list;

  const ListEqualifier(this.list);

  @override
  bool operator ==(Object other) {
    if (other is! ListEqualifier<T>) return false;
    return listEquals(list, other.list);
  }

  @override
  int get hashCode {
    int hash = 0;
    for (var item in list) {
      hash = hash * 31 + item.hashCode;
    }
    return hash;
  }
}

class SetEqualifier<T> {
  final Set<T> set;

  const SetEqualifier(this.set);

  @override
  bool operator ==(Object other) {
    if (other is! SetEqualifier<T>) return false;
    return setEquals(set, other.set);
  }

  @override
  int get hashCode {
    int hash = 0;
    for (var item in set) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}

class _DebugPoint {
  final Offset point;
  final Color color;

  const _DebugPoint({
    required this.point,
    required this.color,
  });
}

void debugPoint(Object key, Offset point,
    [Color color = const Color(0xFF00FF00)]) {
  _debugPoints.mutate((value) {
    value[key] = _DebugPoint(
      point: point,
      color: color,
    );
  });
}

class PointDebugger extends StatelessWidget {
  final Matrix4 parentTransform;

  const PointDebugger({
    super.key,
    required this.parentTransform,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _debugPoints,
      builder: (context, child) {
        return Transform(
          transform: parentTransform,
          child: GroupWidget(children: [
            for (var entry in _debugPoints.value.entries)
              Transform.translate(
                offset: entry.value.point,
                child: Container(
                  width: 10,
                  height: 10,
                  color: entry.value.color,
                ),
              ),
          ]),
        );
      },
    );
  }
}
