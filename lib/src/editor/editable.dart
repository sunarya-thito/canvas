import 'package:canvas/canvas.dart';
import 'package:canvas/src/foundation.dart';
import 'package:canvas/src/layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class EditableProperty<T> implements ValueListenable<T> {
  static EditableProperty<T?> combined<T>(
      Iterable<EditableProperty<T>> properties) {
    assert(properties.isNotEmpty,
        'EditableProperty.combined() must be called with at least one property.');
    assert(properties.map((e) => e.key).toSet().length == 1,
        'EditableProperty.combined() must be called with properties that have the same key.');
    return _CombinedEditableProperty<T>(properties.first.key, properties);
  }

  EditableProperty();
  Key get key;
  Type get type => T;
  set value(T newValue);
}

class _DelegateEditableProperty<T> extends EditableProperty<T> {
  @override
  final Key key;
  final T Function() valueGetter;
  final void Function(T value) valueSetter;
  final Listenable listenable;

  _DelegateEditableProperty({
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

class _CombinedEditableProperty<T> extends EditableProperty<T?> {
  @override
  final Key key;
  final Iterable<EditableProperty<T>> properties;

  _CombinedEditableProperty(this.key, this.properties);

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

class EditableCanvasObjectState extends CanvasObjectState {
  EditableCanvasObjectState({required super.item, super.editor, super.parent});

  EditableProperty<double>? _getEditablePadding(
    Key key,
    double Function(EdgeInsets) getter,
    EdgeInsets Function(EdgeInsets, double) setter,
  ) {
    if (item.layout is FlexLayout) {
      return _DelegateEditableProperty<double>(
        key: key,
        valueGetter: () => getter((item.layout as FlexLayout).padding),
        valueSetter: (value) {
          item.layout = (layout as FlexLayout).copyWith(
            padding: setter(
              (layout as FlexLayout).padding,
              value,
            ),
          );
        },
        listenable: this,
      );
    }
    return null;
  }

  EditableProperty<double>? get topPadding => _getEditablePadding(
        Key('topPadding'),
        (padding) => padding.top,
        (padding, value) => padding.copyWith(top: value),
      );
  EditableProperty<double>? get leftPadding => _getEditablePadding(
        Key('leftPadding'),
        (padding) => padding.left,
        (padding, value) => padding.copyWith(left: value),
      );
  EditableProperty<double>? get rightPadding => _getEditablePadding(
        Key('rightPadding'),
        (padding) => padding.right,
        (padding, value) => padding.copyWith(right: value),
      );
  EditableProperty<double>? get bottomPadding => _getEditablePadding(
        Key('bottomPadding'),
        (padding) => padding.bottom,
        (padding, value) => padding.copyWith(bottom: value),
      );

  EditableProperty<double> _getEditableBorderRadius(
    Key key,
    double Function(BorderRadius?) getter,
    BorderRadius? Function(BorderRadius?, double) setter,
  ) {
    return _DelegateEditableProperty<double>(
      key: key,
      valueGetter: () => getter(item.borderRadius),
      valueSetter: (value) {
        item.borderRadius = setter(item.borderRadius, value);
      },
      listenable: this,
    );
  }

  EditableProperty<double> get topLeftRadius => _getEditableBorderRadius(
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
  EditableProperty<double> get topRightRadius => _getEditableBorderRadius(
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
  EditableProperty<double> get bottomLeftRadius => _getEditableBorderRadius(
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
  EditableProperty<double> get bottomRightRadius => _getEditableBorderRadius(
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

  EditableProperty<double?>? _getEditableAnchor(
    Key key,
    double? Function(AbsoluteLayoutData) getter,
    AbsoluteLayoutData Function(AbsoluteLayoutData, double?) setter,
  ) {
    if (item.layoutData is AbsoluteLayoutData) {
      return _DelegateEditableProperty<double?>(
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

  EditableProperty<double?>? get topAnchor => _getEditableAnchor(
        Key('topAnchor'),
        (layoutData) => layoutData.top,
        (layoutData, value) => layoutData.copyWith(top: value),
      );
  EditableProperty<double?>? get leftAnchor => _getEditableAnchor(
        Key('leftAnchor'),
        (layoutData) => layoutData.left,
        (layoutData, value) => layoutData.copyWith(left: value),
      );
  EditableProperty<double?>? get rightAnchor => _getEditableAnchor(
        Key('rightAnchor'),
        (layoutData) => layoutData.right,
        (layoutData, value) => layoutData.copyWith(right: value),
      );
  EditableProperty<double?>? get bottomAnchor => _getEditableAnchor(
        Key('bottomAnchor'),
        (layoutData) => layoutData.bottom,
        (layoutData, value) => layoutData.copyWith(bottom: value),
      );

  EditableProperty<double?> _getEditableConstraints(
    Key key,
    double? Function(BoxConstraints) getter,
    BoxConstraints Function(BoxConstraints, double?) setter,
  ) {
    return _DelegateEditableProperty<double?>(
      key: key,
      valueGetter: () => getter(item.constraints),
      valueSetter: (value) {
        item.constraints = setter(item.constraints, value);
      },
      listenable: this,
    );
  }

  EditableProperty<double?> get minWidth => _getEditableConstraints(
        Key('minWidth'),
        (constraints) =>
            constraints.minWidth == 0 ? null : constraints.minWidth,
        (constraints, value) => constraints.copyWith(minWidth: value ?? 0),
      );

  EditableProperty<double?> get minHeight => _getEditableConstraints(
        Key('minHeight'),
        (constraints) =>
            constraints.minHeight == 0 ? null : constraints.minHeight,
        (constraints, value) => constraints.copyWith(minHeight: value ?? 0),
      );

  EditableProperty<double?> get maxWidth => _getEditableConstraints(
        Key('maxWidth'),
        (constraints) => constraints.maxWidth == double.infinity
            ? null
            : constraints.maxWidth,
        (constraints, value) =>
            constraints.copyWith(maxWidth: value ?? double.infinity),
      );

  EditableProperty<double?> get maxHeight => _getEditableConstraints(
        Key('maxHeight'),
        (constraints) => constraints.maxHeight == double.infinity
            ? null
            : constraints.maxHeight,
        (constraints, value) =>
            constraints.copyWith(maxHeight: value ?? double.infinity),
      );

  EditableProperty<FlexAlignment>? get horizontalAlignment {
    if (item.layout is FlexLayout) {
      var parent = this.parent;
      if (parent is CanvasObjectState) {
        var parentLayout = parent.item.layout;
        if (parentLayout is FlexLayout) {
          var direction = parentLayout.direction;
          return _DelegateEditableProperty<FlexAlignment>(
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
      }
    }
    return null;
  }

  EditableProperty<FlexAlignment>? get verticalAlignment {
    if (item.layout is FlexLayout) {
      var parent = this.parent;
      if (parent is CanvasObjectState) {
        var parentLayout = parent.item.layout;
        if (parentLayout is FlexLayout) {
          var direction = parentLayout.direction;
          return _DelegateEditableProperty<FlexAlignment>(
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
      }
    }
    return null;
  }

  // EditableProperty<double?> get width {
  //   return _DelegateEditableProperty(
  //     key: Key('width'),
  //     valueGetter: valueGetter,
  //     valueSetter: valueSetter,
  //     listenable: this,
  //   );
  // }
  // EditableProperty<double?>? _getEditableSize(
  //   double? Function(FixedLayoutData) getter,
  //   FixedLayoutData Function(FixedLayoutData, double?) setter,
  // ) {
  //   if (item.layoutData is FixedLayoutData) {
  //     return _DelegateEditableProperty<double?>(
  //       key: const Key('size'),
  //       valueGetter: () => getter(item.layoutData as FixedLayoutData),
  //       valueSetter: (value) {
  //         item.layoutData = setter(
  //           item.layoutData as FixedLayoutData,
  //           value,
  //         );
  //       },
  //       listenable: this,
  //     );
  //   }
  //   return null;
  // }

  // EditableProperty<double?>? get width {
  //   var editableWidth = _getEditableSize(
  //     (layoutData) => layoutData.width.value,
  //     (layoutData, value) => layoutData.copyWith(
  //       width: value == null
  //           ? SizeConstraint.intrinsic()
  //           : value == double.infinity
  //               ? SizeConstraint.unconstrained()
  //               : SizeConstraint.fixed(value),
  //     ),
  //   );
  //   editableWidth ??= _getEditableAnchor((layoutData) => layoutData.width,
  //       (layoutData, value) => layoutData.copyWith(width: value));
  //   if (parent is CanvasObjectState && item.layoutData is FlexLayoutData) {
  //     var layoutData = item.layoutData as FlexLayoutData;
  //     var parent = this.parent as CanvasObjectState;
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.vertical) {
  //         editableWidth ??= _DelegateEditableProperty<double?>(
  //           key: const Key('flexWidth'),
  //           valueGetter: () => layoutData.cross.value,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               cross: value == null
  //                   ? SizeConstraint.intrinsic()
  //                   : value == double.infinity
  //                       ? SizeConstraint.unconstrained()
  //                       : SizeConstraint.fixed(value),
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return editableWidth;
  // }

  // EditableProperty<double?>? get height {
  //   var editableHeight = _getEditableSize(
  //     (layoutData) => layoutData.height.value,
  //     (layoutData, value) => layoutData.copyWith(
  //       height: value == null
  //           ? SizeConstraint.intrinsic()
  //           : value == double.infinity
  //               ? SizeConstraint.unconstrained()
  //               : SizeConstraint.fixed(value),
  //     ),
  //   );
  //   editableHeight ??= _getEditableAnchor((layoutData) => layoutData.height,
  //       (layoutData, value) => layoutData.copyWith(height: value));
  //   if (parent is CanvasObjectState && item.layoutData is FlexLayoutData) {
  //     var layoutData = item.layoutData as FlexLayoutData;
  //     var parent = this.parent as CanvasObjectState;
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.horizontal) {
  //         editableHeight ??= _DelegateEditableProperty<double?>(
  //           key: const Key('flexHeight'),
  //           valueGetter: () => layoutData.cross.value,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               cross: value == null
  //                   ? SizeConstraint.intrinsic()
  //                   : value == double.infinity
  //                       ? SizeConstraint.unconstrained()
  //                       : SizeConstraint.fixed(value),
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return editableHeight;
  // }

  // EditableProperty<double?>? get minWidth {
  //   var layoutData = item.layoutData;
  //   var parent = this.parent;
  //   if (layoutData is FixedLayoutData &&
  //       layoutData.width is IntrinsicSizeConstraint) {
  //     return _DelegateEditableProperty<double?>(
  //       key: const Key('minWidth'),
  //       valueGetter: () => (layoutData.width as IntrinsicSizeConstraint).min,
  //       valueSetter: (value) {
  //         item.layoutData = layoutData.copyWith(
  //           width: (layoutData.width as IntrinsicSizeConstraint).copyWith(
  //             min: value,
  //           ),
  //         );
  //       },
  //       listenable: this,
  //     );
  //   } else if (layoutData is FlexLayoutData && parent is CanvasObjectState) {
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.horizontal) {
  //         if (layoutData.cross is IntrinsicSizeConstraint) {
  //           return _DelegateEditableProperty<double?>(
  //             key: const Key('minWidth'),
  //             valueGetter: () =>
  //                 (layoutData.cross as IntrinsicSizeConstraint).min,
  //             valueSetter: (value) {
  //               item.layoutData = layoutData.copyWith(
  //                 cross: (layoutData.cross as IntrinsicSizeConstraint).copyWith(
  //                   min: value,
  //                 ),
  //               );
  //             },
  //             listenable: this,
  //           );
  //         }
  //       } else {
  //         return _DelegateEditableProperty<double?>(
  //           key: const Key('minWidth'),
  //           valueGetter: () => layoutData.min,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               min: value,
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // EditableProperty<double?>? get minHeight {
  //   var layoutData = item.layoutData;
  //   var parent = this.parent;
  //   if (layoutData is FixedLayoutData &&
  //       layoutData.height is IntrinsicSizeConstraint) {
  //     return _DelegateEditableProperty<double?>(
  //       key: const Key('minHeight'),
  //       valueGetter: () => (layoutData.height as IntrinsicSizeConstraint).min,
  //       valueSetter: (value) {
  //         item.layoutData = layoutData.copyWith(
  //           height: (layoutData.height as IntrinsicSizeConstraint).copyWith(
  //             min: value,
  //           ),
  //         );
  //       },
  //       listenable: this,
  //     );
  //   } else if (layoutData is FlexLayoutData && parent is CanvasObjectState) {
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.vertical) {
  //         if (layoutData.cross is IntrinsicSizeConstraint) {
  //           return _DelegateEditableProperty<double?>(
  //             key: const Key('minHeight'),
  //             valueGetter: () =>
  //                 (layoutData.cross as IntrinsicSizeConstraint).min,
  //             valueSetter: (value) {
  //               item.layoutData = layoutData.copyWith(
  //                 cross: (layoutData.cross as IntrinsicSizeConstraint)
  //                     .copyWith(min: value),
  //               );
  //             },
  //             listenable: this,
  //           );
  //         }
  //       } else {
  //         return _DelegateEditableProperty<double?>(
  //           key: const Key('minHeight'),
  //           valueGetter: () => layoutData.min,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               min: value,
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // EditableProperty<double?>? get maxWidth {
  //   var layoutData = item.layoutData;
  //   var parent = this.parent;
  //   if (layoutData is FixedLayoutData &&
  //       layoutData.width is IntrinsicSizeConstraint) {
  //     return _DelegateEditableProperty<double?>(
  //       key: const Key('maxWidth'),
  //       valueGetter: () => (layoutData.width as IntrinsicSizeConstraint).max,
  //       valueSetter: (value) {
  //         item.layoutData = layoutData.copyWith(
  //           width: (layoutData.width as IntrinsicSizeConstraint).copyWith(
  //             max: value,
  //           ),
  //         );
  //       },
  //       listenable: this,
  //     );
  //   } else if (layoutData is FlexLayoutData && parent is CanvasObjectState) {
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.horizontal) {
  //         if (layoutData.cross is IntrinsicSizeConstraint) {
  //           return _DelegateEditableProperty<double?>(
  //             key: const Key('maxWidth'),
  //             valueGetter: () =>
  //                 (layoutData.cross as IntrinsicSizeConstraint).max,
  //             valueSetter: (value) {
  //               item.layoutData = layoutData.copyWith(
  //                 cross: (layoutData.cross as IntrinsicSizeConstraint)
  //                     .copyWith(max: value),
  //               );
  //             },
  //             listenable: this,
  //           );
  //         }
  //       } else {
  //         return _DelegateEditableProperty<double?>(
  //           key: const Key('maxWidth'),
  //           valueGetter: () => layoutData.max,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               max: value,
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // EditableProperty<double?>? get maxHeight {
  //   var layoutData = item.layoutData;
  //   var parent = this.parent;
  //   if (layoutData is FixedLayoutData &&
  //       layoutData.height is IntrinsicSizeConstraint) {
  //     return _DelegateEditableProperty<double?>(
  //       key: const Key('maxHeight'),
  //       valueGetter: () => (layoutData.height as IntrinsicSizeConstraint).max,
  //       valueSetter: (value) {
  //         item.layoutData = layoutData.copyWith(
  //           height: (layoutData.height as IntrinsicSizeConstraint).copyWith(
  //             max: value,
  //           ),
  //         );
  //       },
  //       listenable: this,
  //     );
  //   } else if (layoutData is FlexLayoutData && parent is CanvasObjectState) {
  //     var parentLayout = parent.item.layout;
  //     if (parentLayout is FlexLayout) {
  //       var direction = parentLayout.direction;
  //       if (direction == Axis.vertical) {
  //         if (layoutData.cross is IntrinsicSizeConstraint) {
  //           return _DelegateEditableProperty<double?>(
  //             key: const Key('maxHeight'),
  //             valueGetter: () =>
  //                 (layoutData.cross as IntrinsicSizeConstraint).max,
  //             valueSetter: (value) {
  //               item.layoutData = layoutData.copyWith(
  //                 cross: (layoutData.cross as IntrinsicSizeConstraint)
  //                     .copyWith(max: value),
  //               );
  //             },
  //             listenable: this,
  //           );
  //         }
  //       } else {
  //         return _DelegateEditableProperty<double?>(
  //           key: const Key('maxHeight'),
  //           valueGetter: () => layoutData.max,
  //           valueSetter: (value) {
  //             item.layoutData = layoutData.copyWith(
  //               max: value,
  //             );
  //           },
  //           listenable: this,
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }
}
