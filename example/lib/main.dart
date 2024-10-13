import 'dart:math';

import 'package:canvas/canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(ShadcnApp(
    theme: ThemeData(
      colorScheme: ColorSchemes.darkGreen(),
      radius: 0.5,
    ),
    home: Scaffold(
      child: CanvasExample(),
    ),
  ));
}

class CanvasExample extends StatefulWidget {
  const CanvasExample({super.key});

  @override
  State<CanvasExample> createState() => _CanvasExampleState();
}

double _degToRad(double deg) => deg * (pi / 180);
double _radToDeg(double rad) => rad * (180 / pi);

class _CanvasExampleState extends State<CanvasExample>
    with SingleTickerProviderStateMixin {
  late CanvasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(
      children: [
        BoxCanvasItem(
            debugLabel: 'Red',
            decoration: GestureDetector(
              onTap: () {
                print('Red tapped');
              },
              child: Container(
                color: Colors.red,
                child: Center(
                  child: Text('Red'),
                ),
              ),
            ),
            constraints: FixedConstraints(
              offset: Offset.zero,
              size: Size(100, 100),
              scale: Offset(1, 1),
              rotation: _degToRad(0),
              shear: Offset(0.5, 0.5),
            ),
            children: [
              BoxCanvasItem(
                debugLabel: 'Green',
                decoration: GestureDetector(
                  onTap: () {
                    print('Green tapped');
                  },
                  child: Container(
                    color: Colors.green,
                    child: Center(
                      child: Text('Green'),
                    ),
                  ),
                ),
                children: [
                  BoxCanvasItem(
                    debugLabel: 'Orange',
                    decoration: GestureDetector(
                      onTap: () {
                        print('Orange tapped');
                      },
                      child: Container(
                        color: Colors.orange,
                        child: Center(
                          child: Text('Orange'),
                        ),
                      ),
                    ),
                    constraints: FixedConstraints(
                      offset: Offset(50, 25),
                      size: Size(50, 50),
                      rotation: _degToRad(25),
                    ),
                  ),
                ],
                constraints: FixedConstraints(
                  offset: Offset(100, 100),
                  size: Size(50, 50),
                  scale: Offset(-1, 2),
                  rotation: _degToRad(25),
                ),
              ),
            ]),
        BoxCanvasItem(
          debugLabel: 'Purple',
          decoration: GestureDetector(
            onTap: () {
              print('Purple tapped');
            },
            child: Container(
              color: Colors.purple,
              child: Center(
                child: Text('Purple'),
              ),
            ),
          ),
          constraints: FixedConstraints(
            offset: Offset(200, 0),
            size: Size(100, 100),
            scale: Offset(1, 1),
            rotation: _degToRad(0),
            shear: Offset(0, 0.5),
          ),
          children: [
            BoxCanvasItem(
              debugLabel: 'Yellow',
              decoration: GestureDetector(
                onTap: () {
                  print('Yellow tapped');
                },
                child: Container(
                  color: Colors.yellow,
                  child: Center(
                    child: Text('Yellow'),
                  ),
                ),
              ),
              children: [
                BoxCanvasItem(
                  debugLabel: 'Blue',
                  decoration: GestureDetector(
                    onTap: () {
                      print('Blue tapped');
                    },
                    child: Container(
                      color: Colors.blue,
                      child: Center(
                        child: Text('Blue'),
                      ),
                    ),
                  ),
                  constraints: FixedConstraints(
                    offset: Offset(50, 50),
                    size: Size(50, 50),
                  ),
                ),
              ],
              constraints: FixedConstraints(
                offset: Offset(100, 100),
                size: Size(50, 50),
                scale: Offset(2, 2),
              ),
            ),
          ],
        ),

        // FLEX TEST
        // BoxCanvasItem(
        //     constraints: FixedConstraints(
        //       size: Size(500, 200),
        //     ),
        //     debugLabel: 'Red Flex',
        //     decoration: Container(
        //       color: Colors.red,
        //     ),
        //     layout: FlexLayout(
        //       padding: EdgeInsets.only(
        //         top: 10,
        //         left: 10,
        //         right: 10,
        //         bottom: 10,
        //       ),
        //       gap: 10,
        //       direction: Axis.horizontal,
        //       mainAxisAlignment: FlexAlignment.center,
        //       crossAxisAlignment: FlexAlignment.end,
        //     ),
        //     children: [
        //       BoxCanvasItem(
        //         debugLabel: 'Green Flex',
        //         decoration: Container(
        //           color: Colors.green,
        //         ),
        //         constraints: FlexibleConstraints(
        //           width: SizeConstraint.fixed(100),
        //           height: SizeConstraint.fill(),
        //         ),
        //       ),
        //       BoxCanvasItem(
        //         debugLabel: 'Blue Flex',
        //         decoration: Container(
        //           color: Colors.blue,
        //         ),
        //         layout: FlexLayout(
        //           direction: Axis.vertical,
        //           mainAxisAlignment: FlexAlignment.center,
        //           crossAxisAlignment: FlexAlignment.center,
        //           gap: double.infinity,
        //           padding: EdgeInsets.all(50),
        //         ),
        //         constraints: FlexibleConstraints(
        //           width: SizeConstraint.fillBoxed(100, 550),
        //           height: SizeConstraint.fillBoxed(100, 850),
        //         ),
        //         children: [
        //           BoxCanvasItem(
        //             debugLabel: 'Purple Flex',
        //             decoration: Container(
        //               color: Colors.purple,
        //             ),
        //             constraints: FlexibleConstraints(
        //               width: SizeConstraint.fill(),
        //               height: SizeConstraint.fillLoose(200),
        //             ),
        //           ),
        //           BoxCanvasItem(
        //             debugLabel: 'Yellow Flex',
        //             decoration: Container(
        //               color: Colors.yellow,
        //             ),
        //             constraints: FlexibleConstraints(
        //               width: SizeConstraint.fill(),
        //               height: SizeConstraint.fillLoose(200),
        //             ),
        //           ),
        //           BoxCanvasItem(
        //             debugLabel: 'Yellow Flex',
        //             decoration: Container(
        //               color: Colors.yellow,
        //             ),
        //             constraints: FlexibleConstraints(
        //               width: SizeConstraint.fill(),
        //               height: SizeConstraint.fillLoose(200),
        //             ),
        //           ),
        //         ],
        //       ),
        //       BoxCanvasItem(
        //         debugLabel: 'Orange Flex',
        //         decoration: Container(
        //           color: Colors.orange,
        //         ),
        //         constraints: FlexibleConstraints(
        //           width: SizeConstraint.fixed(100),
        //           height: SizeConstraint.fill(),
        //         ),
        //       ),
        //       BoxCanvasItem(
        //         constraints: FixedConstraints(
        //           offset: Offset(200, 40),
        //           size: Size(100, 100),
        //         ),
        //         debugLabel: 'Gray Flex',
        //         decoration: Container(
        //           color: Colors.gray,
        //         ),
        //       ),
        //     ])
      ],
    );
  }

  int _objectCreationCount = 0;

  bool _shiftDown = false; // using shift
  bool _altDown = false; // using alt
  bool _ctrlDown = false; // using ctrl
  final FocusNode _focusNode = FocusNode();
  ResizeMode _resizeMode = ResizeMode.resize;
  ToolMode _toolMode = ToolMode.select;
  SelectionBehavior _selectionBehavior = SelectionBehavior.contain;
  bool snapToGrid = false;

  List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.teal,
  ];
  List<String> _debugLabels = [
    'Red',
    'Green',
    'Blue',
    'Orange',
    'Purple',
    'Yellow',
    'Pink',
    'Teal',
  ];

  CanvasSelectionHandler? get _selectionHandler {
    switch (_toolMode) {
      case ToolMode.select:
        return null;
      case ToolMode.createBox:
        return CreateObjectHandler(
          controller: _controller,
          createAtRoot: _ctrlDown,
          createItem: (offset, instant) {
            int index = (_objectCreationCount++) % _colors.length;
            return FrameCanvasItem(
              onRefresh: () {
                setState(() {});
              },
              color: _colors[index],
              debugLabel: _debugLabels[index],
              constraints: FixedConstraints(
                offset: offset,
                size: instant ? Size(100, 100) : Size.zero,
              ),
            );
          },
        );
      case ToolMode.createText:
        return CreateObjectHandler(
          controller: _controller,
          createAtRoot: _ctrlDown,
          createItem: (offset, instant) {
            return TextCanvasItem(
              onRefresh: () {
                setState(() {});
              },
              text: 'New Text',
              constraints: FixedConstraints(
                offset: offset,
                size: instant ? Size(100, 100) : Size.zero,
              ),
            );
          },
        );
    }
  }

  List<TreeNode<CanvasItem>> _convert(CanvasItem item) {
    return item.children.whereType<CustomCanvasItem>().map(
      (e) {
        return e._treeItem;
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListenableBuilder(
                    listenable: _controller.childrenListenable,
                    builder: (context, child) {
                      return TreeView<CanvasItem>(
                        nodes: _convert(_controller.root),
                        branchLine: BranchLine.path,
                        allowMultiSelect: true,
                        expandIcon: true,
                        onSelectionChanged:
                            (selectedNodes, multiSelect, selected) {
                          if (multiSelect) {
                            _controller.root.visit(
                              (item) {
                                if (item is! CustomCanvasItem) return;
                                if (selectedNodes.contains(item._treeItem)) {
                                  item.selected = selected;
                                }
                              },
                            );
                          } else {
                            _controller.root.visit(
                              (item) {
                                if (item is! CustomCanvasItem) return;
                                item.selected =
                                    selectedNodes.contains(item._treeItem);
                              },
                            );
                          }
                        },
                        builder: (context, node) {
                          return TreeItemView(
                            onPressed: () {},
                            onExpand: (value) {
                              setState(() {
                                (node.data as CustomCanvasItem)
                                    .setExpanded(value);
                              });
                            },
                            child: Text(node.data.debugLabel ?? 'Item'),
                          );
                        },
                      );
                    }),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.delete):
                      const DeleteObjectIntent(),
                },
                child: Actions(
                  actions: {
                    DeleteObjectIntent: CallbackAction(
                      onInvoke: (intent) {
                        List<CustomCanvasItem> items = [];
                        _controller.root.visit(
                          (item) {
                            if (item is CustomCanvasItem &&
                                item.selectedNotifier.value) {
                              items.add(item);
                            }
                          },
                        );
                        for (final item in items) {
                          item.remove();
                        }
                        return null;
                      },
                    ),
                  },
                  child: Focus(
                    focusNode: _focusNode,
                    onKeyEvent: (node, event) {
                      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                          event.logicalKey == LogicalKeyboardKey.shiftRight) {
                        if (event is KeyDownEvent) {
                          setState(() {
                            _shiftDown = true;
                          });
                        } else if (event is KeyUpEvent) {
                          setState(() {
                            _shiftDown = false;
                          });
                        }
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.altLeft ||
                          event.logicalKey == LogicalKeyboardKey.altRight) {
                        if (event is KeyDownEvent) {
                          setState(() {
                            _altDown = true;
                          });
                        } else if (event is KeyUpEvent) {
                          setState(() {
                            _altDown = false;
                          });
                        }
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                          event.logicalKey == LogicalKeyboardKey.controlRight) {
                        if (event is KeyDownEvent) {
                          setState(() {
                            _ctrlDown = true;
                          });
                        } else if (event is KeyUpEvent) {
                          setState(() {
                            _ctrlDown = false;
                          });
                        }
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Listener(
                      onPointerDown: (event) {
                        _focusNode.requestFocus();
                      },
                      child: CanvasViewport(
                        onReparent: (details) {
                          return _ctrlDown;
                        },
                        selectionHandler: _selectionHandler,
                        gestures: DesktopCanvasGestures(
                          shouldHandleEvent: (event) {
                            return event is PointerScrollEvent &&
                                event is! DesktopPointerScrollEvent;
                          },
                        ),
                        onSelectionEnd: (value) {
                          setState(() {
                            _toolMode = ToolMode.select;
                          });
                        },
                        alignment: Alignment(0, 0.25),
                        controller: _controller,
                        multiSelect: _shiftDown,
                        resizeMode: _resizeMode,
                        proportionalResize: _altDown,
                        symmetricResize: _ctrlDown,
                        anchoredRotate: _altDown,
                        selectionBehavior: _selectionBehavior,
                        snapping: SnappingConfiguration(
                          gridSnapping: snapToGrid ? Offset(10, 10) : null,
                        ),
                        canvasSize: Size(400, 600),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                left: 24,
                right: 24,
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Resize')),
                        child: Toggle(
                          value: _resizeMode == ResizeMode.resize,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _resizeMode = ResizeMode.resize;
                              });
                            }
                          },
                          child: Icon(Icons.crop),
                        ),
                      ),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Scale')),
                        child: Toggle(
                          value: _resizeMode == ResizeMode.scale,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _resizeMode = ResizeMode.scale;
                              });
                            }
                          },
                          child: Icon(Icons.aspect_ratio),
                        ),
                      ),
                      Gap(24),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Select')),
                        child: Toggle(
                          value: _toolMode == ToolMode.select,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _toolMode = ToolMode.select;
                              });
                            }
                          },
                          child: Icon(Icons.select_all),
                        ),
                      ),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Create Box')),
                        child: Toggle(
                          value: _toolMode == ToolMode.createBox,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _toolMode = ToolMode.createBox;
                              });
                            }
                          },
                          child: Icon(Icons.crop_square),
                        ),
                      ),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Create Text')),
                        child: Toggle(
                          value: _toolMode == ToolMode.createText,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _toolMode = ToolMode.createText;
                              });
                            }
                          },
                          child: Icon(Icons.text_fields),
                        ),
                      ),
                      Gap(24),
                      HoverCard(
                        hoverBuilder: (context) {
                          return Card(
                            child: Basic(
                              title: Text('Select Contain'),
                              content: Text(
                                  'Select items that are fully contained\nwithin the selection box.'),
                            ),
                          );
                        },
                        child: Toggle(
                          value:
                              _selectionBehavior == SelectionBehavior.contain,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _selectionBehavior = SelectionBehavior.contain;
                              });
                            }
                          },
                          child: Icon(Icons.join_full),
                        ),
                      ),
                      HoverCard(
                        hoverBuilder: (context) {
                          return Card(
                            child: Basic(
                              title: Text('Select Intersect'),
                              content: Text(
                                  'Select only items that intersect\nwith the selection box.'),
                            ),
                          );
                        },
                        child: Toggle(
                          value:
                              _selectionBehavior == SelectionBehavior.intersect,
                          onChanged: (value) {
                            if (value) {
                              setState(() {
                                _selectionBehavior =
                                    SelectionBehavior.intersect;
                              });
                            }
                          },
                          child: Icon(Icons.join_inner),
                        ),
                      ),
                      Gap(24),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text('Snap to Grid')),
                        child: Toggle(
                          value: snapToGrid,
                          onChanged: (value) {
                            setState(() {
                              snapToGrid = value;
                            });
                          },
                          child: Icon(Icons.grid_on),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ToolMode {
  select,
  createBox,
  createText,
}

class CustomCanvasItem extends CanvasItem {
  late TreeItem<CanvasItem> _treeItem;
  final VoidCallback onRefresh;
  CustomCanvasItem({
    super.children,
    super.debugLabel,
    super.constraints,
    super.selected = false,
    super.clipContent = false,
    required this.onRefresh,
  }) {
    childrenListenable.addListener(() {
      _refreshTreeNodes();
      onRefresh();
    });
    selectedNotifier.addListener(
      () {
        _treeItem = _treeItem.updateState(
          selected: selectedNotifier.value,
        );
        onRefresh();
      },
    );
    _treeItem = TreeItem(
      data: this,
    );
  }

  void setExpanded(bool expanded) {
    _treeItem = _treeItem.updateState(
      expanded: expanded,
    );
    onRefresh();
  }

  void _listener() {
    _refreshTreeNodes();
  }

  void _refreshTreeNodes() {
    for (final child in children) {
      child.childrenListenable.addListener(_listener);
      child.selectedNotifier.addListener(_listener);
    }
    _treeItem = _treeItem.updateChildren(
      children.map(
        (e) {
          return (e as CustomCanvasItem)._treeItem;
        },
      ).toList(),
    );
  }
}

class FrameCanvasItem extends CustomCanvasItem {
  final ValueNotifier<Color> colorNotifier = ValueNotifier(Colors.red);
  final ValueNotifier<BorderRadius> borderRadiusNotifier =
      ValueNotifier(BorderRadius.zero);
  FrameCanvasItem({
    super.children,
    super.debugLabel,
    super.constraints,
    super.selected,
    Color color = Colors.red,
    required super.onRefresh,
  }) {
    colorNotifier.value = color;
  }

  @override
  Widget? build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([colorNotifier, borderRadiusNotifier]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorNotifier.value,
            borderRadius: borderRadiusNotifier.value,
          ),
        );
      },
    );
  }
}

class TextCanvasItem extends CustomCanvasItem {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<TextStyle> styleNotifier = ValueNotifier(const TextStyle(
    fontSize: 16,
    color: Colors.black,
  ));
  final ValueNotifier<TextAlign> alignNotifier = ValueNotifier(TextAlign.left);
  final ValueNotifier<TextAlignVertical> verticalAlignNotifier =
      ValueNotifier(TextAlignVertical.top);

  TextCanvasItem({
    super.children,
    super.debugLabel,
    super.constraints,
    super.selected,
    required super.onRefresh,
    String text = '',
  }) {
    controller.text = text;
  }

  @override
  bool get hasContent => true;

  @override
  Widget? build(BuildContext context) {
    return ListenableBuilder(
        listenable: Listenable.merge({
          styleNotifier,
          alignNotifier,
          verticalAlignNotifier,
          // contentFocusedNotifier,
        }),
        builder: (context, child) {
          // if (!contentFocusedNotifier.value) {
          //   return Text(
          //     controller.text,
          //     style: styleNotifier.value,
          //     textAlign: alignNotifier.value,
          //     overflow: TextOverflow.visible,
          //   );
          // }
          return TextField(
            padding: EdgeInsets.zero,
            border: false,
            maxLines: null,
            expands: true,
            controller: controller,
            style: styleNotifier.value,
            textAlign: alignNotifier.value,
            textAlignVertical: verticalAlignNotifier.value,
            isCollapsed: true,
          );
        });
  }
}

class DeleteObjectIntent extends Intent {
  const DeleteObjectIntent();
}
