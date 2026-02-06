import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/layout/responsive.dart';
import 'package:skeleton/generated/grpc_pb/editor.pb.dart' as grpc;
import 'package:skeleton/presentation/screens/editor/bloc/editor_bloc.dart';
import 'package:skeleton/presentation/screens/editor/bloc/editor_event.dart';
import 'package:skeleton/presentation/screens/editor/bloc/editor_state.dart';

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

  String _labelForType(grpc.TransformType t) {
    switch (t) {
      case grpc.TransformType.TRANSFORM_TYPE_FIX:
        return 'Исправить';
      case grpc.TransformType.TRANSFORM_TYPE_IMPROVE:
        return 'Улучшить';
      case grpc.TransformType.TRANSFORM_TYPE_BEAUTIFY:
        return 'Красиво';
      case grpc.TransformType.TRANSFORM_TYPE_PARAPHRASE:
        return 'Другими словами';
      case grpc.TransformType.TRANSFORM_TYPE_SHORTEN:
        return 'Кратко';
      case grpc.TransformType.TRANSFORM_TYPE_SIMPLIFY:
        return 'Проще';
      case grpc.TransformType.TRANSFORM_TYPE_MAKE_COMPLEX:
        return 'Сложнее';
      case grpc.TransformType.TRANSFORM_TYPE_MORE_FORMAL:
        return 'Более формально';
      case grpc.TransformType.TRANSFORM_TYPE_MORE_CASUAL:
        return 'Разговорный стиль';
      case grpc.TransformType.TRANSFORM_TYPE_UNSPECIFIED:
        return 'Выберите режим';
    }

    return 'Выберите режим';
  }

  List<grpc.TransformType> get _types => const [
    grpc.TransformType.TRANSFORM_TYPE_FIX,
    grpc.TransformType.TRANSFORM_TYPE_IMPROVE,
    grpc.TransformType.TRANSFORM_TYPE_BEAUTIFY,
    grpc.TransformType.TRANSFORM_TYPE_PARAPHRASE,
    grpc.TransformType.TRANSFORM_TYPE_SHORTEN,
    grpc.TransformType.TRANSFORM_TYPE_SIMPLIFY,
    grpc.TransformType.TRANSFORM_TYPE_MAKE_COMPLEX,
    grpc.TransformType.TRANSFORM_TYPE_MORE_FORMAL,
    grpc.TransformType.TRANSFORM_TYPE_MORE_CASUAL,
  ];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<EditorBloc, EditorState>(
      listenWhen: (p, c) => p.outputText != c.outputText || p.error != c.error,
      listener: (context, state) {
        if (state.outputText.isNotEmpty) {
          _outputController.text = state.outputText;
        }

        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: colorScheme.error,
            ),
          );
          context.read<EditorBloc>().add(const EditorClearError());
        }
      },
      builder: (context, state) {
        final isMobile = Breakpoints.isMobile(context);

        return Scaffold(
          body: SafeArea(
            child: isMobile
              ? _buildMobileLayout(context, state, theme, colorScheme)
              : _buildDesktopLayout(context, state, theme, colorScheme),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    EditorState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildTopBar(context, state, theme, colorScheme, true),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: colorScheme.surface,
                  child: TabBar(
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.edit_note, size: 22),
                        text: 'Исходный',
                      ),
                      Tab(
                        icon: Icon(Icons.check_circle_outline, size: 22),
                        text: 'Результат',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTextField(context, state, theme, colorScheme, true),
                      _buildTextField(context, state, theme, colorScheme, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    EditorState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildTopBar(context, state, theme, colorScheme, false),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(context, state, theme, colorScheme, true),
              ),
              Container(
                width: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildTextField(context, state, theme, colorScheme, false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    EditorState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: isMobile
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildModeSelector(context, state, true)),
                const SizedBox(width: 8),
                Expanded(child: _buildModelSelector(context, state, true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMarkdownToggle(context, state),
                const Spacer(),
                _buildApplyButton(context, state, true),
              ],
            ),
          ],
        )
        : SizedBox(
          height: 56,
          child: Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Редактор',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 200,
                child: _buildModeSelector(context, state, false),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: _buildModelSelector(context, state, false),
              ),
              const Spacer(),
              _buildMarkdownToggle(context, state),
              const SizedBox(width: 8),
              _buildApplyButton(context, state, false),
            ],
          ),
        ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    EditorState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isInput,
  ) {
    final controller = isInput ? _inputController : _outputController;
    final isReadOnly = !isInput;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isInput ? Icons.edit_note : Icons.check_circle_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isInput ? 'Исходный текст' : 'Результат',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isInput && _outputController.text.isNotEmpty) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Скопировать',
                  onPressed: () {
                    final text = _outputController.text;
                    if (text.isEmpty) return;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Скопировано'),
                          ],
                        ),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !state.isLoading && isInput,
              readOnly: isReadOnly,
              maxLines: null,
              expands: true,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: isInput
                  ? 'Введите текст для редактирования...'
                  : (state.isLoading
                    ? 'Обработка...'
                    : null),
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, EditorState state, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonFormField<grpc.TransformType>(
        initialValue: state.type,
        isDense: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
        items: _types.map((type) => DropdownMenuItem(
          value: type,
          child: Text(
            _labelForType(type),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        )).toList(),
        onChanged: state.isLoading
          ? null
          : (v) {
            if (v != null) {
              context.read<EditorBloc>().add(EditorTypeChanged(v));
            }
          },
        dropdownColor: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        iconSize: 20,
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, EditorState state, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: (state.selectedModel != null && state.models.contains(state.selectedModel))
          ? state.selectedModel
          : (state.models.isNotEmpty ? state.models.first : null),
        isDense: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
        items: state.models.map((m) => DropdownMenuItem(
          value: m,
          child: Text(
            m,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        )).toList(),
        onChanged: state.isLoading
          ? null
          : (v) => context.read<EditorBloc>().add(EditorModelChanged(v)),
        dropdownColor: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        iconSize: 20,
      ),
    );
  }

  Widget _buildMarkdownToggle(BuildContext context, EditorState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code,
            size: 16,
            color: state.preserveMarkdown
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          const Text('Markdown'),
        ],
      ),
      selected: state.preserveMarkdown,
      onSelected: state.isLoading
        ? null
        : (selected) {
          context.read<EditorBloc>().add(
            EditorPreserveMarkdownChanged(selected),
          );
        },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: state.preserveMarkdown
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: state.preserveMarkdown ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, EditorState state, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FilledButton.icon(
      onPressed: state.isLoading
        ? null
        : () {
          context.read<EditorBloc>().add(EditorInputChanged(_inputController.text));
          context.read<EditorBloc>().add(const EditorTransformPressed());
        },
      icon: state.isLoading
        ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
          ),
        )
        : const Icon(Icons.auto_fix_high, size: 20),
      label: Text(
        state.isLoading ? 'Обработка…' : 'Применить',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 28,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
