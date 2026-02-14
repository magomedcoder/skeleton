import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:legion/presentation/widgets/code_block_builder.dart';

class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? minLines;
  final int? maxLines;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.minLines = 5,
    this.maxLines = 10,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildTab(
                context,
                index: 0,
                icon: Icons.edit,
                label: 'Редактор',
              ),
              _buildTab(
                context,
                index: 1,
                icon: Icons.preview,
                label: 'Предпросмотр',
              ),
              const Spacer(),
              if (_selectedTabIndex == 0)
                _buildMarkdownButtons(context),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: (widget.minLines ?? 5) * 24.0,
            maxHeight: (widget.maxLines ?? 10) * 24.0,
          ),
          child: _selectedTabIndex == 0
            ? _buildEditor(context)
            : _buildPreview(context),
        ),
      ],
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedTabIndex == index;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMarkdownButton(
          context,
          icon: Icons.format_bold,
          tooltip: 'Жирный текст (**текст**)',
          onTap: () => _insertMarkdown('**', '**'),
        ),
        _buildMarkdownButton(
          context,
          icon: Icons.format_italic,
          tooltip: 'Курсив (*текст*)',
          onTap: () => _insertMarkdown('*', '*'),
        ),
        _buildMarkdownButton(
          context,
          icon: Icons.code,
          tooltip: 'Код (`код`)',
          onTap: () => _insertMarkdown('`', '`'),
        ),
        _buildMarkdownButton(
          context,
          icon: Icons.link,
          tooltip: 'Ссылка ([текст](url))',
          onTap: () => _insertMarkdown('[', '](url)'),
        ),
        _buildMarkdownButton(
          context,
          icon: Icons.format_list_bulleted,
          tooltip: 'Список',
          onTap: () => _insertMarkdown('- ', ''),
        ),
      ],
    );
  }

  Widget _buildMarkdownButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start +
            prefix.length +
            selectedText.length +
            suffix.length,
        ),
      );
    } else {
      final position = selection.baseOffset;
      final newText = text.replaceRange(position, position, '$prefix$suffix');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: position + prefix.length),
      );
    }
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Введите описание задачи (поддерживается Markdown)',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.controller.text.trim();

    if (text.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'Предпросмотр появится здесь',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodyMedium,
            h1: theme.textTheme.headlineSmall,
            h2: theme.textTheme.titleLarge,
            h3: theme.textTheme.titleMedium,
            listIndent: 24,
            blockquote: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            code: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          builders: {'pre': CodeBlockBuilder()},
        ),
      ),
    );
  }
}
