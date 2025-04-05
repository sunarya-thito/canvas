import 'package:canvas/canvas.dart';
import 'package:example/cases/flex_case.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract class TestCase {
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

  void _setSelectedCase(int newCase) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ),
        const Divider(),
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
                    allowReparenting: true,
                    controller: controller,
                    root: testCases[_selectedCase!].root,
                  ),
                ),
                ResizablePane(
                    initialSize: 300,
                    minSize: 200,
                    child: ListView(
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
                                      const Gap(4),
                                      property.buildControl(context),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    )),
              ],
            ),
    );
  }
}
