import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin EditorPropertyOwner {}

class CompositeEditorPropertyOwner with EditorPropertyOwner {
  final List<EditorPropertyOwner> owners;

  const CompositeEditorPropertyOwner(this.owners);

  @override
  bool operator ==(Object other) {
    if (other is! CompositeEditorPropertyOwner) return false;
    return listEquals(owners, other.owners);
  }

  @override
  int get hashCode {
    return owners.hashCode;
  }
}

abstract class EditorProperty<T> implements ValueListenable<T> {
  static EditorProperty<T?> combined<T>(
      Iterable<EditorProperty<T>> properties) {
    assert(properties.isNotEmpty,
        'EditableProperty.combined() must be called with at least one property.');
    assert(properties.map((e) => e.key).toSet().length == 1,
        'EditableProperty.combined() must be called with properties that have the same key.');
    List<EditorPropertyOwner> owners = [];
    void addOrExpand(EditorPropertyOwner owner) {
      if (owner is CompositeEditorPropertyOwner) {
        owners.addAll(owner.owners);
      } else {
        owners.add(owner);
      }
    }

    for (var property in properties) {
      addOrExpand(property.owner);
    }
    return _CombinedEditableProperty<T>(
      CompositeEditorPropertyOwner(owners),
      properties.first.key,
      properties,
    );
  }

  EditorProperty();
  EditorPropertyOwner get owner;
  Key get key;
  Type get type => T;
  set value(T newValue);

  EditorProperty<T?> combineWith(EditorProperty<T> other) {
    List<EditorPropertyOwner> owners = [];
    void addOrExpand(EditorPropertyOwner owner) {
      if (owner is CompositeEditorPropertyOwner) {
        owners.addAll(owner.owners);
      } else {
        owners.add(owner);
      }
    }

    addOrExpand(owner);
    addOrExpand(other.owner);
    return _CombinedEditableProperty<T>(
      CompositeEditorPropertyOwner(owners),
      key,
      [this, other],
    );
  }
}

class _DelegateEditableProperty<T> extends EditorProperty<T> {
  @override
  final EditorPropertyOwner owner;
  @override
  final Key key;
  final T Function() valueGetter;
  final void Function(T value) valueSetter;
  final Listenable listenable;

  _DelegateEditableProperty({
    required this.owner,
    required this.key,
    required this.valueGetter,
    required this.valueSetter,
    required this.listenable,
  });

  @override
  T get value => valueGetter();

  @override
  set value(T newValue) {
    valueSetter(newValue);
  }

  @override
  void addListener(VoidCallback listener) {
    listenable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenable.removeListener(listener);
  }
}

class _CombinedEditableProperty<T> extends EditorProperty<T?> {
  @override
  final EditorPropertyOwner owner;
  @override
  final Key key;
  final Iterable<EditorProperty<T>> properties;

  _CombinedEditableProperty(this.owner, this.key, this.properties);

  @override
  T? get value {
    T? aggregatedValue;
    for (var property in properties) {
      if (aggregatedValue == null) {
        aggregatedValue = property.value;
      } else if (aggregatedValue != property.value) {
        return null;
      }
    }
    return aggregatedValue;
  }

  @override
  set value(T? newValue) {
    if (newValue is T) {
      // will pass null if T is nullable
      for (var property in properties) {
        property.value = newValue;
      }
    }
  }

  @override
  void addListener(VoidCallback listener) {
    for (var property in properties) {
      property.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (var property in properties) {
      property.removeListener(listener);
    }
  }
}

mixin EditableCanvasItemState {
  List<EditorProperty> get properties;
}

class EditableCanvasObject extends CanvasObject {
  EditableCanvasObject({
    super.debugLabel,
    super.children,
    super.layoutData,
    super.layout,
    super.borderRadius,
    super.clipContent,
    super.layoutGrids,
    super.locked,
  });

  @override
  EditableCanvasObjectState createState(
      {CanvasItemState? parent, CanvasEditorHandler? editor}) {
    return EditableCanvasObjectState(
        item: this, parent: parent, editor: editor);
  }
}

class EditableCanvasObjectState extends CanvasObjectState
    with EditableCanvasItemState, EditorPropertyOwner {
  EditableCanvasObjectState({required super.item, super.editor, super.parent});

  EditorProperty<double> get rotation {
    return _DelegateEditableProperty<double>(
      owner: this,
      key: Key('rotation'),
      valueGetter: () =>
          rotationFromShear(item.layoutData.shear ?? Offset.zero) * 180 / pi,
      valueSetter: (value) {
        item.layoutData = item.layoutData.withShear(Rotation(value * pi / 180));
      },
      listenable: this,
    );
  }

  EditorProperty<double>? _getEditablePadding(
    Key key,
    double Function(EdgeInsets) getter,
    EdgeInsets Function(EdgeInsets, double) setter,
  ) {
    return _DelegateEditableProperty<double>(
      owner: this,
      key: key,
      valueGetter: () => getter(item.layout.padding),
      valueSetter: (value) {
        item.layout = item.layout.withNewPadding(
          setter(item.layout.padding, value),
        );
      },
      listenable: this,
    );
  }

  EditorProperty<double>? get topPadding => _getEditablePadding(
        Key('topPadding'),
        (padding) => padding.top,
        (padding, value) => padding.copyWith(top: value),
      );
  EditorProperty<double>? get leftPadding => _getEditablePadding(
        Key('leftPadding'),
        (padding) => padding.left,
        (padding, value) => padding.copyWith(left: value),
      );
  EditorProperty<double>? get rightPadding => _getEditablePadding(
        Key('rightPadding'),
        (padding) => padding.right,
        (padding, value) => padding.copyWith(right: value),
      );
  EditorProperty<double>? get bottomPadding => _getEditablePadding(
        Key('bottomPadding'),
        (padding) => padding.bottom,
        (padding, value) => padding.copyWith(bottom: value),
      );

  EditorProperty<double> _getEditableBorderRadius(
    Key key,
    double Function(BorderRadius?) getter,
    BorderRadius? Function(BorderRadius?, double) setter,
  ) {
    return _DelegateEditableProperty<double>(
      owner: this,
      key: key,
      valueGetter: () => getter(item.borderRadius),
      valueSetter: (value) {
        item.borderRadius = setter(item.borderRadius, value);
      },
      listenable: this,
    );
  }

  EditorProperty<double> get topLeftRadius => _getEditableBorderRadius(
        Key('topLeftRadius'),
        (borderRadius) => borderRadius?.topLeft.x ?? 0,
        (borderRadius, value) =>
            borderRadius?.copyWith(
              topLeft: Radius.circular(value),
            ) ??
            BorderRadius.only(
              topLeft: Radius.circular(value),
            ),
      );
  EditorProperty<double> get topRightRadius => _getEditableBorderRadius(
        Key('topRightRadius'),
        (borderRadius) => borderRadius?.topRight.x ?? 0,
        (borderRadius, value) =>
            borderRadius?.copyWith(
              topRight: Radius.circular(value),
            ) ??
            BorderRadius.only(
              topRight: Radius.circular(value),
            ),
      );
  EditorProperty<double> get bottomLeftRadius => _getEditableBorderRadius(
        Key('bottomLeftRadius'),
        (borderRadius) => borderRadius?.bottomLeft.x ?? 0,
        (borderRadius, value) =>
            borderRadius?.copyWith(
              bottomLeft: Radius.circular(value),
            ) ??
            BorderRadius.only(
              bottomLeft: Radius.circular(value),
            ),
      );
  EditorProperty<double> get bottomRightRadius => _getEditableBorderRadius(
        Key('bottomRightRadius'),
        (borderRadius) => borderRadius?.bottomRight.x ?? 0,
        (borderRadius, value) =>
            borderRadius?.copyWith(
              bottomRight: Radius.circular(value),
            ) ??
            BorderRadius.only(
              bottomRight: Radius.circular(value),
            ),
      );

  EditorProperty<double?>? _getEditableAnchor(
    Key key,
    double? Function(AbsoluteLayoutData) getter,
    AbsoluteLayoutData Function(AbsoluteLayoutData, double?) setter,
  ) {
    if (item.layoutData is AbsoluteLayoutData) {
      return _DelegateEditableProperty<double?>(
        owner: this,
        key: key,
        valueGetter: () => getter(item.layoutData as AbsoluteLayoutData),
        valueSetter: (value) {
          item.layoutData = setter(
            item.layoutData as AbsoluteLayoutData,
            value,
          );
        },
        listenable: this,
      );
    }
    return null;
  }

  EditorProperty<double?>? get topAnchor => _getEditableAnchor(
        Key('topAnchor'),
        (layoutData) => layoutData.top,
        (layoutData, value) => layoutData.copyWith(top: value),
      );
  EditorProperty<double?>? get leftAnchor => _getEditableAnchor(
        Key('leftAnchor'),
        (layoutData) => layoutData.left,
        (layoutData, value) => layoutData.copyWith(left: value),
      );
  EditorProperty<double?>? get rightAnchor => _getEditableAnchor(
        Key('rightAnchor'),
        (layoutData) => layoutData.right,
        (layoutData, value) => layoutData.copyWith(right: value),
      );
  EditorProperty<double?>? get bottomAnchor => _getEditableAnchor(
        Key('bottomAnchor'),
        (layoutData) => layoutData.bottom,
        (layoutData, value) => layoutData.copyWith(bottom: value),
      );

  EditorProperty<double?> _getEditableConstraints(
    Key key,
    double? Function(BoxConstraints) getter,
    BoxConstraints Function(BoxConstraints, double?) setter,
  ) {
    return _DelegateEditableProperty<double?>(
      owner: this,
      key: key,
      valueGetter: () => getter(item.constraints),
      valueSetter: (value) {
        item.constraints = setter(item.constraints, value);
      },
      listenable: this,
    );
  }

  EditorProperty<double?> get minWidth => _getEditableConstraints(
        Key('minWidth'),
        (constraints) =>
            constraints.minWidth == 0 ? null : constraints.minWidth,
        (constraints, value) => constraints.copyWith(minWidth: value ?? 0),
      );

  EditorProperty<double?> get minHeight => _getEditableConstraints(
        Key('minHeight'),
        (constraints) =>
            constraints.minHeight == 0 ? null : constraints.minHeight,
        (constraints, value) => constraints.copyWith(minHeight: value ?? 0),
      );

  EditorProperty<double?> get maxWidth => _getEditableConstraints(
        Key('maxWidth'),
        (constraints) => constraints.maxWidth == double.infinity
            ? null
            : constraints.maxWidth,
        (constraints, value) =>
            constraints.copyWith(maxWidth: value ?? double.infinity),
      );

  EditorProperty<double?> get maxHeight => _getEditableConstraints(
        Key('maxHeight'),
        (constraints) => constraints.maxHeight == double.infinity
            ? null
            : constraints.maxHeight,
        (constraints, value) =>
            constraints.copyWith(maxHeight: value ?? double.infinity),
      );

  EditorProperty<FlexAlignment>? get horizontalAlignment {
    if (item.layout is FlexLayout) {
      var direction = (item.layout as FlexLayout).direction;
      return _DelegateEditableProperty<FlexAlignment>(
        owner: this,
        key: Key('horizontalAlignment'),
        valueGetter: () => direction == Axis.horizontal
            ? (item.layout as FlexLayout).mainAxisAlignment
            : (item.layout as FlexLayout).crossAxisAlignment,
        valueSetter: (value) {
          item.layout = direction == Axis.horizontal
              ? (item.layout as FlexLayout).copyWith(
                  mainAxisAlignment: value,
                )
              : (item.layout as FlexLayout).copyWith(
                  crossAxisAlignment: value,
                );
        },
        listenable: this,
      );
    }
    return null;
  }

  EditorProperty<FlexAlignment>? get verticalAlignment {
    if (item.layout is FlexLayout) {
      var direction = (item.layout as FlexLayout).direction;
      return _DelegateEditableProperty<FlexAlignment>(
        owner: this,
        key: Key('verticalAlignment'),
        valueGetter: () => direction == Axis.horizontal
            ? (item.layout as FlexLayout).crossAxisAlignment
            : (item.layout as FlexLayout).mainAxisAlignment,
        valueSetter: (value) {
          item.layout = direction == Axis.horizontal
              ? (item.layout as FlexLayout).copyWith(
                  crossAxisAlignment: value,
                )
              : (item.layout as FlexLayout).copyWith(
                  mainAxisAlignment: value,
                );
        },
        listenable: this,
      );
    }
    return null;
  }

  EditorProperty<double>? get spacing {
    if (item.layout is FlexLayout) {
      return _DelegateEditableProperty<double>(
        owner: this,
        key: Key('spacing'),
        valueGetter: () => (item.layout as FlexLayout).spacing,
        valueSetter: (value) {
          item.layout = (item.layout as FlexLayout).copyWith(
            spacing: value,
          );
        },
        listenable: this,
      );
    }
    return null;
  }

  EditorProperty<LayoutType> get layoutType {
    return _DelegateEditableProperty(
      owner: this,
      key: Key('layout'),
      valueGetter: () {
        if (item.layout is FlexLayout) {
          return LayoutType.flex;
        }
        return LayoutType.none;
      },
      valueSetter: (value) {
        if (value == LayoutType.flex && item.layout is! FlexLayout) {
          // convert all AbsoluteChildren into FixedChildren
          setState(() {
            for (var child in children) {
              child.item.layoutData = FixedLayoutData(
                width: SizeConstraint.fixed(child.size.width),
                height: SizeConstraint.fixed(child.size.height),
              );
            }
            item.layout = FlexLayout(
              direction: analyzePossibleFlexDirection(),
              mainAxisAlignment: FlexAlignment.start,
              crossAxisAlignment: FlexAlignment.start,
              padding: analyzePossiblePadding(),
              spacing: analyzePossibleSpacing(),
            );
          });
        } else if (value == LayoutType.none && item.layout is! FixedLayout) {
          // convert all FixedChildren into AbsoluteChildren
          setState(() {
            for (var child in children) {
              if (child.item.layoutData is! AbsoluteLayoutData) {
                child.item.layoutData = AbsoluteLayoutData(
                  top: child.parentData.position.dy,
                  left: child.parentData.position.dx,
                  width: child.size.width,
                  height: child.size.height,
                );
              }
            }
            item.layout = FixedLayout();
          });
        }
      },
      listenable: this,
    );
  }

  @override
  List<EditorProperty> get properties {
    var properties = <EditorProperty>[];
    void addIfNotNull(EditorProperty? property) {
      if (property != null) {
        properties.add(property);
      }
    }

    addIfNotNull(rotation);
    addIfNotNull(topPadding);
    addIfNotNull(leftPadding);
    addIfNotNull(rightPadding);
    addIfNotNull(bottomPadding);
    addIfNotNull(topLeftRadius);
    addIfNotNull(topRightRadius);
    addIfNotNull(bottomLeftRadius);
    addIfNotNull(bottomRightRadius);
    addIfNotNull(topAnchor);
    addIfNotNull(leftAnchor);
    addIfNotNull(rightAnchor);
    addIfNotNull(bottomAnchor);
    addIfNotNull(minWidth);
    addIfNotNull(minHeight);
    addIfNotNull(maxWidth);
    addIfNotNull(maxHeight);
    addIfNotNull(horizontalAlignment);
    addIfNotNull(verticalAlignment);
    addIfNotNull(layoutType);
    addIfNotNull(spacing);
    return properties;
  }
}

enum LayoutType {
  none,
  flex,
}
