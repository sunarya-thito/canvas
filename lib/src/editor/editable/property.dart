import 'package:canvas/canvas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class EditablePropertyCategory {
  final String key;
  const EditablePropertyCategory(this.key);
  List<EditablePropertyCategoryView>? getViews(CanvasItemState editable);
}

class EditablePropertyCategoryView {
  final List<EditablePropertyCategory>? subCategories;
  final List<EditablePropertyProvider>? properties;
  const EditablePropertyCategoryView({
    this.subCategories,
    this.properties,
  });
}

abstract class EditablePropertyProvider<V> {
  static const EditablePropertyProvider<FlexAlignment>
      verticalAlignmentProvider =
      EditableVerticalAlignmentProvider('verticalAlignment');
  static const EditablePropertyProvider<FlexAlignment>
      horizontalAlignmentProvider =
      EditableHorizontalAlignmentProvider('horizontalAlignment');
  static const EditablePropertyProvider<double?> minWidthProvider =
      EditableMinWidthProvider('minWidth');
  static const EditablePropertyProvider<double?> minHeightProvider =
      EditableMinHeightProvider('minHeight');
  static const EditablePropertyProvider<double?> maxWidthProvider =
      EditableMaxWidthProvider('maxWidth');
  static const EditablePropertyProvider<double?> maxHeightProvider =
      EditableMaxHeightProvider('maxHeight');
  static const EditablePropertyProvider<Axis> directionProvider =
      EditableDirectionProvider('direction');
  static const EditablePropertyProvider<LayoutType> layoutProvider =
      EditableLayoutProvider('layout');
  static const EditablePropertyProvider<bool> absoluteProvider =
      EditableAbsoluteProvider('absolute');
  static const EditablePropertyProvider<double> topPaddingProvider =
      EditableTopPaddingProvider('topPadding');
  static const EditablePropertyProvider<double> leftPaddingProvider =
      EditableLeftPaddingProvider('leftPadding');
  static const EditablePropertyProvider<double> rightPaddingProvider =
      EditableRightPaddingProvider('rightPadding');
  static const EditablePropertyProvider<double> bottomPaddingProvider =
      EditableBottomPaddingProvider('bottomPadding');
  static const EditablePropertyProvider<double> horizontalPaddingProvider =
      EditableHorizontalPaddingProvider('horizontalPadding');
  static const EditablePropertyProvider<double> verticalPaddingProvider =
      EditableVerticalPaddingProvider('verticalPadding');
  static const EditablePropertyProvider<double> allPaddingProvider =
      EditableAllPaddingProvider('allPadding');
  static const EditablePropertyProvider<Position?> topPositionProvider =
      EditableTopPositionProvider('topPosition');
  static const EditablePropertyProvider<Position?> leftPositionProvider =
      EditableLeftPositionProvider('leftPosition');
  static const EditablePropertyProvider<Position?> rightPositionProvider =
      EditableRightPositionProvider('rightPosition');
  static const EditablePropertyProvider<Position?> bottomPositionProvider =
      EditableBottomPositionProvider('bottomPosition');
  static const EditablePropertyProvider<double> rotationProvider =
      EditableRotationProvider('rotation');
  static const EditablePropertyProvider<double> shearXProvider =
      EditableShearXProvider('shearX');
  static const EditablePropertyProvider<double> shearYProvider =
      EditableShearYProvider('shearY');
  static const EditablePropertyProvider<SizeConstraint?> widthProvider =
      EditableWidthProvider('width');
  static const EditablePropertyProvider<SizeConstraint?> heightProvider =
      EditableHeightProvider('height');
  static const EditablePropertyProvider<double?> spacingProvider =
      EditableSpacingProvider('spacing');

  static const List<EditablePropertyProvider> providers = [
    verticalAlignmentProvider,
    horizontalAlignmentProvider,
    minWidthProvider,
    minHeightProvider,
    maxWidthProvider,
    maxHeightProvider,
    directionProvider,
    layoutProvider,
    absoluteProvider,
    topPaddingProvider,
    leftPaddingProvider,
    rightPaddingProvider,
    bottomPaddingProvider,
    horizontalPaddingProvider,
    verticalPaddingProvider,
    allPaddingProvider,
    topPositionProvider,
    leftPositionProvider,
    rightPositionProvider,
    bottomPositionProvider,
    rotationProvider,
    shearXProvider,
    shearYProvider,
    widthProvider,
    heightProvider,
  ];

  static EditablePropertyProvider? maybeFind(String key) {
    for (var provider in providers) {
      if (provider.key == key) return provider;
    }
    return null;
  }

  static EditablePropertyProvider find(String key) {
    for (var provider in providers) {
      if (provider.key == key) return provider;
    }
    throw Exception('EditablePropertyProvider not found for key: $key');
  }

  final String key;
  const EditablePropertyProvider(this.key);
  V? handleGetValue(CanvasItemState editable);
  bool handleSetValue(CanvasItemState editable, V newValue);
  EditableProperty<V>? createProperty(CanvasItemState editable) {
    return SingleEditableProperty<V>(this, editable);
  }

  EditableProperty<V>? createCompoundProperty(List<CanvasItemState> editables) {
    if (editables.isEmpty) return null;
    if (editables.length == 1) {
      return createProperty(editables.first);
    } else {
      return CompoundEditableProperty<V>(this, editables);
    }
  }
}

abstract class EditableProperty<V> implements ValueListenable<V?> {
  EditablePropertyProvider<V> get provider;
  Type get type;
  Object get owner;
  bool applyValue(V newValue);
}

class SingleEditableProperty<V>
    with ChangeNotifier
    implements EditableProperty<V> {
  @override
  final EditablePropertyProvider<V> provider;
  final CanvasItemState editable;

  SingleEditableProperty(this.provider, this.editable);

  @override
  Type get type => V;

  @override
  Object get owner => editable;

  @override
  V? get value {
    return provider.handleGetValue(editable);
  }

  @override
  bool applyValue(V newValue) {
    return provider.handleSetValue(editable, newValue);
  }

  @override
  void addListener(VoidCallback listener) {
    editable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    editable.removeListener(listener);
  }
}

class CompoundEditableProperty<V>
    with ChangeNotifier
    implements EditableProperty<V> {
  @override
  final EditablePropertyProvider<V> provider;
  final List<CanvasItemState> editables;

  CompoundEditableProperty(this.provider, this.editables);

  @override
  bool applyValue(V newValue) {
    bool hasChanged = false;
    for (var editable in editables) {
      if (provider.handleSetValue(editable, newValue)) {
        hasChanged = true;
      }
    }
    return hasChanged;
  }

  @override
  Object get owner => _EquatableList(editables);

  @override
  Type get type => V;

  @override
  V? get value {
    _NullableValue<V>? value;
    for (var editable in editables) {
      var newValue = provider.handleGetValue(editable);
      if (value == null) {
        value = _NullableValue(newValue);
      } else if (value.value != newValue) {
        return null;
      }
    }
    return value?.value;
  }
}

class _NullableValue<V> {
  final V? value;
  const _NullableValue(this.value);
}

class _EquatableList<T> {
  final List<T> list;
  const _EquatableList(this.list);

  @override
  bool operator ==(Object other) {
    if (other is! _EquatableList<T>) return false;
    return listEquals(list, other.list);
  }

  @override
  int get hashCode => list.hashCode;
}
