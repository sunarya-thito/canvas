import 'package:canvas/canvas.dart';
import 'package:example/cases/flex_case.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract class TestCase extends ChangeNotifier {
  String get name;
  String get description;
  List<TestProperty> get properties;
  CanvasRoot get root;

  void update() {}
}

abstract class TestProperty<T> extends ValueNotifier<T> {
  final String name;

  TestProperty({
    required this.name,
    required T value,
  }) : super(value);

  Widget buildControl(BuildContext context);
}

class StringProperty extends TestProperty<String> {
  StringProperty({
    required super.name,
    required super.value,
  });

  @override
  Widget buildControl(BuildContext context) {
    return TextField(
      initialValue: value,
      onChanged: (value) {
        this.value = value;
      },
    );
  }
}

class NumberProperty extends TestProperty<double> {
  NumberProperty({
    required super.name,
    required super.value,
  });

  @override
  Widget buildControl(BuildContext context) {
    return TextField(
      initialValue: value.toString(),
      onChanged: (value) {
        this.value = double.tryParse(value) ?? this.value;
      },
      features: const [
        InputFeature.spinner(),
      ],
      submitFormatters: [
        TextInputFormatters.mathExpression(),
      ],
    );
  }
}

class EnumProperty<T extends Enum> extends TestProperty<T> {
  final List<Enum> values;

  EnumProperty({
    required super.name,
    required super.value,
    required this.values,
  });

  @override
  Widget buildControl(BuildContext context) {
    return Select(
      value: value,
      onChanged: (value) {
        if (value != null) {
          this.value = value;
        }
      },
      popup: SelectPopup(
        items: SelectItemList(
          children: values.map(
            (e) {
              return SelectItemButton(value: e, child: Text(e.name));
            },
          ).toList(),
        ),
      ).call,
      itemBuilder: (context, value) {
        return Text(value.name);
      },
    );
  }
}

class BoolProperty extends TestProperty<bool> {
  BoolProperty({
    required super.name,
    required super.value,
  });

  @override
  Widget buildControl(BuildContext context) {
    return Checkbox(
      state: value ? CheckboxState.checked : CheckboxState.unchecked,
      onChanged: (value) {
        this.value = value == CheckboxState.checked;
      },
    );
  }
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

  bool _showRuler = false;
  bool _allowReparenting = true;
  bool _symmetricResize = false;
  bool _proportionalResize = false;
  bool _multiSelect = false;
  bool _enableSnapping = true;

  int _dragMode = 0; // 0 = select, 1 = move, 2 = create object

  void _setSelectedCase(int newCase) {
    controller.value = const CanvasEditorTransform();
    int? oldCase = _selectedCase;
    if (oldCase != null) {
      var oldTestCase = testCases[oldCase];
      for (var property in oldTestCase.properties) {
        property.removeListener(_onPropertyUpdate);
      }
    }
    _selectedCase = newCase;
    var newTestCase = testCases[newCase];
    for (var property in newTestCase.properties) {
      property.addListener(_onPropertyUpdate);
    }
    _onPropertyUpdate();
  }

  void _closeCase() {
    if (_selectedCase != null) {
      var testCase = testCases[_selectedCase!];
      for (var property in testCase.properties) {
        property.removeListener(_onPropertyUpdate);
      }
      _selectedCase = null;
    }
  }

  void _onPropertyUpdate() {
    if (_selectedCase != null) {
      var testCase = testCases[_selectedCase!];
      testCase.update();
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
                      root: testCases[_selectedCase!].root,
                    ),
                  ),
                  ResizablePane(
                      initialSize: 300,
                      minSize: 200,
                      child: ListenableBuilder(
                          listenable: testCases[_selectedCase!],
                          builder: (context, _) {
                            return ListView(
                              padding: const EdgeInsets.all(8),
                              children: [
                                ...testCases[_selectedCase!].properties.map(
                                  (property) {
                                    return ListenableBuilder(
                                      listenable: property,
                                      builder: (context, _) {
                                        return Container(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(property.name).small.muted,
                                              gap(4),
                                              property.buildControl(context),
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
