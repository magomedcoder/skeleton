import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_bloc.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_event.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_state.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorBloc>().add(const EditorStarted());
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditorBloc, EditorState>(
      listenWhen: (p, c) => p.outputText != c.outputText || p.error != c.error,
      listener: (context, state) {
        if (state.outputText.isNotEmpty) {
          _outputController.text = state.outputText;
        }

        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
          context.read<EditorBloc>().add(const EditorClearError());
        }
      },
      builder: (context, state) {
        final isMobile = Breakpoints.isMobile(context);

        final modelDropdown = InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Модель',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: (state.selectedModel != null && state.models.contains(state.selectedModel))
                ? state.selectedModel
                : (state.models.isNotEmpty ? state.models.first : null),
              items: state.models.map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m, overflow: TextOverflow.ellipsis),
                ),
              ).toList(),
              onChanged: state.isLoading ? null : (v) => context.read<EditorBloc>().add(EditorModelChanged(v)),
            ),
          ),
        );

        final applyButton = FilledButton.icon(
          onPressed: state.isLoading
            ? null
            : () {
                context.read<EditorBloc>().add(EditorInputChanged(_inputController.text));
                context.read<EditorBloc>().add(const EditorTransformPressed());
              },
          icon: state.isLoading
            ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Icon(Icons.auto_fix_high),
          label: Text(state.isLoading ? 'Обработка…' : 'Применить'),
        );

        final inputField = TextField(
          controller: _inputController,
          enabled: !state.isLoading,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            labelText: 'Исходный текст',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        );

        final outputField = TextField(
          controller: _outputController,
          readOnly: true,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            labelText: 'Результат',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        );

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile) ...[
                    Row(children: [applyButton]),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: modelDropdown),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        SizedBox(width: 260, child: modelDropdown),
                        const Spacer(),
                        applyButton,
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: isMobile
                      ? DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Текст'),
                                Tab(text: 'Результат'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: TabBarView(
                                children: [inputField, outputField],
                              ),
                            ),
                          ],
                        ),
                      )
                      : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: inputField),
                          const SizedBox(width: 12),
                          Expanded(child: outputField),
                        ],
                      ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
