import 'dart:async';

import 'package:canvas/canvas.dart';
import 'package:example/cases/empty_case.dart';
import 'package:example/cases/flex_case.dart';
import 'package:example/property.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract class TestCase extends ChangeNotifier {
  String get name;
  String get description;
  // CanvasParent createRoot();
  CanvasEditor openEditor();
}

class CanvasExampleApp extends StatefulWidget {
  const CanvasExampleApp({super.key});

  @override
  State<CanvasExampleApp> createState() => _CanvasExampleAppState();
}

class _CanvasExampleAppState extends State<CanvasExampleApp> {
  final List<TestCase> testCases = [
    FlexTestCase(),
    EmptyCase(),
  ];
  int? _selectedCase;
  Selection? _localSelection;

  bool _showRuler = false;
  // bool _allowReparenting = true;
  // bool _symmetricResize = false;
  // bool _proportionalResize = false;
  // bool _multiSelect = false;
  // bool _enableSnapping = true;

  int _objectCount = 0;

  int _dragMode = 0; // 0 = select, 1 = move, 2 = create object

  // CanvasRoot? _canvasRoot;
  CanvasEditor? _editor;
  StreamSubscription<CanvasEvent>? _eventSubscription;

  void _setSelectedCase(int newCase) {
    _selectedCase = newCase;
    _eventSubscription?.cancel();
    _editor?.dispose();
    _editor = testCases[newCase].openEditor();
    _eventSubscription = _editor!.listen(_listenEvent);
  }

  void _listenEvent(CanvasEvent event) {
    if (event is CanvasLocalSelectionChangedNotification) {
      setState(() {
        _localSelection = event.selection;
      });
    }
  }

  void _closeCase() {
    _localSelection = null;
    if (_selectedCase != null) {
      _selectedCase = null;
    }
  }

  Widget buildDrawer(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: testCases.length,
        separatorBuilder: (context, index) => const Divider(
          height: 8,
        ),
        itemBuilder: (context, index) {
          return CardButton(
            alignment: Alignment.centerLeft,
            child: Basic(
              title: Text(testCases[index].name),
              subtitle: Text(testCases[index].description),
            ),
            onPressed: () {
              setState(() {
                _setSelectedCase(index);
              });
              closeDrawer(context);
            },
          );
        },
      ),
    );
  }

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        headers: [
          AppBar(
            title: const Text('Canvas Example'),
            leading: [
              IconButton.ghost(
                icon: const Icon(LucideIcons.menu),
                onPressed: () {
                  openDrawer(
                    context: context,
                    builder: buildDrawer,
                    position: OverlayPosition.left,
                  );
                },
              ),
            ],
            trailing: [
              if (_selectedCase != null) ...[
                IconButton.ghost(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    setState(() {
                      _closeCase();
                    });
                  },
                ),
              ],
            ],
          ),
          const Divider(),
          if (_selectedCase != null) ...[
            AppBar(
              child: Row(
                spacing: 8,
                children: [
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Show Ruler')).call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _showRuler,
                      onChanged: (value) {
                        setState(() {
                          _showRuler = value;
                        });
                      },
                      child: const Icon(LucideIcons.ruler),
                    ),
                  ),
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Enable Snapping'))
                            .call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _editor?.snappingConfiguration.enableSnapping ??
                          false,
                      onChanged: (value) {
                        setState(() {
                          _editor?.snappingConfiguration =
                              SnappingConfiguration(
                            enableSnapping: value,
                          );
                        });
                      },
                      child: const Icon(LucideIcons.grid2x2X),
                    ),
                  ),
                  const VerticalDivider(),
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Allow Reparenting'))
                            .call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _editor?.allowReparenting ?? false,
                      onChanged: (value) {
                        setState(() {
                          _editor?.allowReparenting = value;
                        });
                      },
                      child: const Icon(LucideIcons.link),
                    ),
                  ),
                  const VerticalDivider(),
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Symmetric Resize'))
                            .call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _editor?.symmetricResize ?? false,
                      onChanged: (value) {
                        setState(() {
                          _editor?.symmetricResize = value;
                        });
                      },
                      child: const Icon(LucideIcons.squareArrowOutUpRight),
                    ),
                  ),
                  Tooltip(
                    tooltip: const TooltipContainer(
                            child: Text('Proportional Resize'))
                        .call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _editor?.proportionalResize ?? false,
                      onChanged: (value) {
                        setState(() {
                          _editor?.proportionalResize = value;
                        });
                      },
                      child: const Icon(LucideIcons.ratio),
                    ),
                  ),
                  const VerticalDivider(),
                  Tooltip(
                    tooltip: const TooltipContainer(child: Text('Multi Select'))
                        .call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _editor?.selectionMode ==
                          CanvasSelectionMode.multiple,
                      onChanged: (value) {
                        setState(() {
                          _editor?.selectionMode = value
                              ? CanvasSelectionMode.multiple
                              : CanvasSelectionMode.single;
                        });
                      },
                      child: const Icon(LucideIcons.copyCheck),
                    ),
                  ),
                  const VerticalDivider(),
                  // Select Mode
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Select Mode')).call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _dragMode == 0,
                      onChanged: (value) {
                        setState(() {
                          _dragMode = value ? 0 : _dragMode;
                        });
                      },
                      child: const Icon(LucideIcons.mousePointerClick),
                    ),
                  ),
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Move Mode')).call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _dragMode == 1,
                      onChanged: (value) {
                        setState(() {
                          _dragMode = value ? 1 : _dragMode;
                        });
                      },
                      child: const Icon(LucideIcons.move),
                    ),
                  ),
                  Tooltip(
                    tooltip:
                        const TooltipContainer(child: Text('Create Mode')).call,
                    child: Toggle(
                      style: const ButtonStyle.ghostIcon(),
                      value: _dragMode == 2,
                      onChanged: (value) {
                        setState(() {
                          _dragMode = value ? 2 : _dragMode;
                        });
                      },
                      child: const Icon(LucideIcons.plus),
                    ),
                  ),
                  const VerticalDivider(),
                  // reset button
                  Tooltip(
                    tooltip: const TooltipContainer(child: Text('Reset')).call,
                    child: IconButton.ghost(
                      icon: const Icon(LucideIcons.refreshCw),
                      onPressed: () {
                        _setSelectedCase(_selectedCase!);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        ],
        child: _selectedCase == null
            ? const Center(
                child: Text('Select a scene'),
              )
            : ResizablePanel(
                direction: Axis.horizontal,
                children: [
                  ResizablePane.flex(
                    child: Shortcuts(
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.delete):
                            CanvasDeleteSelectedObjectsIntent(),
                      },
                      child: CanvasEditorWidget(
                        showRuler: _showRuler,
                        editor: _editor!,
                        // controller: controller,
                        // gesture: _dragMode == 0
                        //     ? const EditorSelectDragGesture()
                        //     : _dragMode == 1
                        //         ? const EditorMoveDragGesture()
                        //         : EditorCreateObjectDragGesture(
                        //             createItem: (editor) {
                        //               return EditableCanvasObject(
                        //                 debugLabel:
                        //                     'New Object ${++_objectCount}',
                        //               );
                        //             },
                        //           ),
                        // onLocalSelectionChanged: (value) {
                        //   setState(() {
                        //     _localSelection = value;
                        //   });
                        // },
                        // root: _canvasRoot!,
                      ),
                    ),
                  ),
                  ResizablePane(
                      initialSize: 300,
                      minSize: 200,
                      child: _localSelection == null
                          ? const Center(
                              child: Text('Select an Object'),
                            )
                          : ListenableBuilder(
                              listenable:
                                  Listenable.merge(_localSelection!.items),
                              builder: (context, _) {
                                return ListView(
                                  padding: const EdgeInsets.all(8),
                                  children: [
                                    ...EditablePropertyProvider.providers.map(
                                      (provider) {
                                        var property =
                                            provider.createCompoundProperty(
                                                _localSelection!.items);
                                        return ListenableBuilder(
                                          listenable: Listenable.merge([
                                            property,
                                          ]),
                                          builder: (context, _) {
                                            if (property == null) {
                                              return const SizedBox.shrink();
                                            }
                                            return Container(
                                              key: ValueKey(_PropertyKey(
                                                  property.owner,
                                                  property.provider.key)),
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(property.provider.key)
                                                      .small
                                                      .muted,
                                                  gap(4),
                                                  buildPropertyRenderer(
                                                      context, property),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              })),
                ],
              ),
      ),
    );
  }
}

class _PropertyKey {
  final Object item;
  final String key;

  const _PropertyKey(this.item, this.key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _PropertyKey && other.item == item && other.key == key;
  }

  @override
  int get hashCode => Object.hash(item, key);
}
