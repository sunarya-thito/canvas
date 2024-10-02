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
        // BoxCanvasItem(
        //     debugLabel: 'Red',
        //     decoration: GestureDetector(
        //       onTap: () {
        //         print('Red tapped');
        //       },
        //       child: Container(
        //         color: Colors.red,
        //         child: Center(
        //           child: Text('Red'),
        //         ),
        //       ),
        //     ),
        //     layout: AbsoluteLayout(
        //       offset: Offset.zero,
        //       size: Size(100, 100),
        //       scale: Offset(2, 2),
        //       rotation: _degToRad(0),
        //     ),
        //     children: [
        //       BoxCanvasItem(
        //         debugLabel: 'Green',
        //         decoration: GestureDetector(
        //           onTap: () {
        //             print('Green tapped');
        //           },
        //           child: Container(
        //             color: Colors.green,
        //             child: Center(
        //               child: Text('Green'),
        //             ),
        //           ),
        //         ),
        //         children: [
        //           BoxCanvasItem(
        //             debugLabel: 'Orange',
        //             decoration: GestureDetector(
        //               onTap: () {
        //                 print('Orange tapped');
        //               },
        //               child: Container(
        //                 color: Colors.orange,
        //                 child: Center(
        //                   child: Text('Orange'),
        //                 ),
        //               ),
        //             ),
        //             layout: AbsoluteLayout(
        //               offset: Offset(50, 50),
        //               size: Size(50, 50),
        //               rotation: _degToRad(25),
        //             ),
        //           ),
        //         ],
        //         layout: AbsoluteLayout(
        //           offset: Offset(100, 100),
        //           size: Size(50, 50),
        //           rotation: _degToRad(44),
        //         ),
        //       ),
        //     ]),
        // BoxCanvasItem(
        //   debugLabel: 'Purple',
        //   decoration: GestureDetector(
        //     onTap: () {
        //       print('Purple tapped');
        //     },
        //     child: Container(
        //       color: Colors.purple,
        //       child: Center(
        //         child: Text('Purple'),
        //       ),
        //     ),
        //   ),
        //   layout: AbsoluteLayout(
        //     offset: Offset(200, 0),
        //     size: Size(100, 100),
        //     scale: Offset(1, 1),
        //     rotation: _degToRad(25),
        //   ),
        //   children: [
        //     BoxCanvasItem(
        //       debugLabel: 'Yellow',
        //       decoration: GestureDetector(
        //         onTap: () {
        //           print('Yellow tapped');
        //         },
        //         child: Container(
        //           color: Colors.yellow,
        //           child: Center(
        //             child: Text('Yellow'),
        //           ),
        //         ),
        //       ),
        //       children: [
        //         BoxCanvasItem(
        //           debugLabel: 'Blue',
        //           decoration: GestureDetector(
        //             onTap: () {
        //               print('Blue tapped');
        //             },
        //             child: Container(
        //               color: Colors.blue,
        //               child: Center(
        //                 child: Text('Blue'),
        //               ),
        //             ),
        //           ),
        //           layout: AbsoluteLayout(
        //             offset: Offset(50, 50),
        //             size: Size(50, 50),
        //           ),
        //         ),
        //       ],
        //       layout: AbsoluteLayout(
        //         offset: Offset(100, 100),
        //         size: Size(50, 50),
        //         scale: Offset(2, 2),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
    _controller.childListenable.addListener(() {
      setState(() {
        _refreshTreeNodes();
      });
    });
  }

  bool _shiftDown = false; // using shift
  bool _altDown = false; // using alt
  bool _ctrlDown = false; // using ctrl
  FocusNode _focusNode = FocusNode();
  ResizeMode _resizeMode = ResizeMode.resize;
  ToolMode _toolMode = ToolMode.select;

  CanvasSelectionHandler? get _selectionHandler {
    switch (_toolMode) {
      case ToolMode.select:
        return null;
      case ToolMode.createBox:
        return CreateObjectHandler(
          controller: _controller,
          createAtRoot: _ctrlDown,
          createItem: (offset, instant) {
            return CustomCanvasItem(
              onChanged: () {
                setState(() {
                  _refreshTreeNodes();
                });
              },
              decoration: Container(
                color: Colors.red,
              ),
              layout: AbsoluteLayout(
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
            return CustomCanvasItem(
              onChanged: () {
                setState(() {
                  _refreshTreeNodes();
                });
              },
              decoration: GestureDetector(
                onTap: () {
                  print('Text tapped');
                },
                child: Text(
                  'Text',
                  style: TextStyle(color: Colors.black, fontSize: 24),
                  overflow: TextOverflow.visible,
                ),
              ),
              layout: AbsoluteLayout(
                offset: offset,
                size: instant ? Size(100, 100) : Size.zero,
              ),
            );
          },
        );
    }
  }

  final ValueNotifier<List<TreeNode<CanvasItem>>> _nodes = ValueNotifier([]);

  void _refreshTreeNodes() {
    _nodes.value = _convert(_controller.root);
  }

  List<TreeNode<CanvasItem>> _convert(CanvasItem item) {
    return item.children.map(
      (e) {
        return TreeItem(
          data: e,
          selected: e.selected,
          expanded: (e as CustomCanvasItem).expanded,
          children: _convert(e),
        );
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
                    listenable: _nodes,
                    builder: (context, child) {
                      return TreeView<CanvasItem>(
                        nodes: _nodes.value,
                        branchLine: BranchLine.path,
                        allowMultiSelect: true,
                        expandIcon: true,
                        onSelectionChanged:
                            (selectedNodes, multiSelect, selected) {},
                        builder: (context, node) {
                          return TreeItemView(
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
              Focus(
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
                      return !_ctrlDown;
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
                    canvasSize: Size(400, 600),
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
                      Select<ResizeMode>(
                        value: _resizeMode,
                        onChanged: (value) {
                          setState(() {
                            _resizeMode = value ?? ResizeMode.resize;
                          });
                        },
                        popupWidthConstraint: PopoverConstraint.anchorMaxSize,
                        orderSelectedFirst: false,
                        children: [
                          SelectItemButton(
                            value: ResizeMode.resize,
                            child: Text('Resize'),
                          ),
                          SelectItemButton(
                            value: ResizeMode.scale,
                            child: Text('Scale'),
                          ),
                        ],
                        itemBuilder: (context, item) {
                          switch (item) {
                            case ResizeMode.resize:
                              return Text('Resize');
                            case ResizeMode.scale:
                              return Text('Scale');
                          }
                        },
                      ),
                      Gap(24),
                      Toggle(
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
                      Toggle(
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
                      Toggle(
                        value: _toolMode == ToolMode.createText,
                        onChanged: (value) {
                          if (value) {
                            setState(() {
                              _toolMode = ToolMode.createText;
                            });
                          }
                        },
                        child: Icon(Icons.text_fields),
                      )
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

class CustomCanvasItem extends BoxCanvasItem {
  final VoidCallback onChanged;
  CustomCanvasItem({
    required this.onChanged,
    super.children = const [],
    super.debugLabel,
    super.decoration,
    super.layout = const AbsoluteLayout(),
    super.selected = false,
  }) {
    childListenable.addListener(onChanged);
    selectedNotifier.addListener(onChanged);
  }

  bool expanded = false;
}
