import 'package:canvas/canvas.dart';
import 'package:example/cases/flex_case.dart';
import 'package:example/property.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract class TestCase extends ChangeNotifier {
  String get name;
  String get description;
  CanvasRoot get root;
}

class CanvasExampleApp extends StatefulWidget {
  const CanvasExampleApp({super.key});

  @override
  State<CanvasExampleApp> createState() => _CanvasExampleAppState();
}

class _CanvasExampleAppState extends State<CanvasExampleApp> {
  final CanvasEditorController controller = CanvasEditorController();
  final List<TestCase> testCases = [
    FlexTestCase(),
  ];
  int? _selectedCase;
  Selection? _localSelection;

  bool _showRuler = false;
  bool _allowReparenting = true;
  bool _symmetricResize = false;
  bool _proportionalResize = false;
  bool _multiSelect = false;
  bool _enableSnapping = true;

  int _dragMode = 0; // 0 = select, 1 = move, 2 = create object

  void _setSelectedCase(int newCase) {
    controller.value = const CanvasEditorTransform();
    _selectedCase = newCase;
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
        separatorBuilder: (context, index) => const Divider(),
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
                      value: _enableSnapping,
                      onChanged: (value) {
                        setState(() {
                          _enableSnapping = value;
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
                      value: _allowReparenting,
                      onChanged: (value) {
                        setState(() {
                          _allowReparenting = value;
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
                      value: _symmetricResize,
                      onChanged: (value) {
                        setState(() {
                          _symmetricResize = value;
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
                      value: _proportionalResize,
                      onChanged: (value) {
                        setState(() {
                          _proportionalResize = value;
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
                      value: _multiSelect,
                      onChanged: (value) {
                        setState(() {
                          _multiSelect = value;
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
                    child: CanvasEditor(
                      allowReparenting: _allowReparenting,
                      symmetricResize: _symmetricResize,
                      proportionalResize: _proportionalResize,
                      selectionMode: _multiSelect
                          ? CanvasSelectionMode.multiple
                          : CanvasSelectionMode.single,
                      snappingConfiguration: SnappingConfiguration(
                        enableSnapping: _enableSnapping,
                      ),
                      showRuler: _showRuler,
                      controller: controller,
                      gesture: _dragMode == 0
                          ? const EditorSelectDragGesture()
                          : const EditorMoveDragGesture(),
                      onLocalSelectionChanged: (value) {
                        setState(() {
                          _localSelection = value;
                        });
                      },
                      root: testCases[_selectedCase!].root,
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
                              listenable: Listenable.merge(
                                  _localSelection!.selectedItems),
                              builder: (context, _) {
                                return ListView(
                                  padding: const EdgeInsets.all(8),
                                  children: [
                                    ..._localSelection!.editableProperties.map(
                                      (property) {
                                        return ListenableBuilder(
                                          listenable: property,
                                          builder: (context, _) {
                                            return Container(
                                              key: ValueKey(_PropertyKey(
                                                  property.owner,
                                                  property.key)),
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text((property.key
                                                              as ValueKey<
                                                                  String>)
                                                          .value)
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
  final EditorPropertyOwner item;
  final Key key;

  const _PropertyKey(this.item, this.key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _PropertyKey && other.item == item && other.key == key;
  }

  @override
  int get hashCode => Object.hash(item, key);
}
