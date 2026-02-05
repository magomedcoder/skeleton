import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' show highlight, Node, Result;
import 'package:skeleton/core/code_highlight_settings.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder({this.textStyle});

  final TextStyle? textStyle;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'pre') return null;

    final code = element.textContent;

    if (code.isEmpty) return null;

    final rawLang = _languageFromPreElement(element);
    final language = (rawLang != null && rawLang.isNotEmpty)
      ? rawLang
      : 'plaintext';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? atomOneDarkTheme : githubTheme;
    final baseStyle = textStyle ?? const TextStyle(
      fontSize: 13,
      fontFamily: 'monospace',
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: _SelectableCodeBlock(
        code: code.replaceAll('\t', '     '),
        language: language,
        theme: theme,
        baseStyle: baseStyle,
      ),
    );
  }
}

String? _languageFromPreElement(md.Element pre) {
  if (pre.children == null || pre.children!.isEmpty) return null;

  for (final node in pre.children!) {
    if (node is! md.Element || node.tag != 'code') continue;

    final cls = node.attributes['class'] ?? node.attributes['className'];
    if (cls == null) continue;

    for (final token in cls.split(' ')) {
      final t = token.trim();
      if (t.startsWith('language-') && t.length > 9) {
        final lang = t.substring(9).trim();

        if (lang.isNotEmpty) return lang;

        break;
      }
    }
  }
  return null;
}

Result _detectLanguageFromSubset(String code) {
  Result best = highlight.parse(code, language: 'plaintext');
  int bestRelevance = best.relevance ?? 0;
  for (final lang in CodeHighlightSettings.autoDetectLanguages) {
    try {
      final result = highlight.parse(code, language: lang);
      final r = result.relevance ?? 0;
      if (r > bestRelevance) {
        bestRelevance = r;
        best = result;
        best.language = lang;
      }
    } catch (_) {

    }
  }
  return best;
}

const String _rootKey = 'root';

List<TextSpan> _nodesToTextSpans(
  List<Node> nodes,
  Map<String, TextStyle> theme,
) {
  final spans = <TextSpan>[];
  List<List<TextSpan>> stack = [];

  void traverse(Node node, List<TextSpan> currentSpans) {
    if (node.value != null) {
      currentSpans.add(node.className == null
        ? TextSpan(text: node.value)
        : TextSpan(
          text: node.value,
          style: theme[node.className!],
        ),
      );
    } else if (node.children != null) {
      final tmp = <TextSpan>[];
      currentSpans.add(TextSpan(
        children: tmp,
        style: theme[node.className!],
      ));
      stack.add(currentSpans);

      for (final n in node.children!) {
        traverse(n, tmp);
      }

      if (stack.isNotEmpty) {
        stack.removeLast();
      }
    }
  }

  for (final node in nodes) {
    traverse(node, spans);
  }

  return spans;
}

class _SelectableCodeBlock extends StatefulWidget {
  const _SelectableCodeBlock({
    required this.code,
    required this.language,
    required this.theme,
    required this.baseStyle,
  });

  final String code;
  final String language;
  final Map<String, TextStyle> theme;
  final TextStyle baseStyle;

  @override
  State<_SelectableCodeBlock> createState() => _SelectableCodeBlockState();
}

class _SelectableCodeBlockState extends State<_SelectableCodeBlock> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));

    if (!mounted) return;

    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final useAutoDetect = widget.language == 'plaintext' || widget.language.isEmpty;
    final result = useAutoDetect
      ? _detectLanguageFromSubset(widget.code)
      : highlight.parse(widget.code, language: widget.language);
    final nodes = result.nodes ?? [];
    final displayLanguage = result.language ?? widget.language;
    final spans = _nodesToTextSpans(nodes, widget.theme);
    final rootStyle = widget.baseStyle.merge(
      TextStyle(
        color: widget.theme[_rootKey]?.color,
        backgroundColor: widget.theme[_rootKey]?.backgroundColor,
      ),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
      ? const Color(0xffabb2bf)
      : const Color(0xff333333);
    final copiedColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme[_rootKey]?.backgroundColor ?? const Color(0xfff8f8f8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: widget.theme[_rootKey]?.backgroundColor?.withValues(alpha: 0.6) ?? const Color(0xfff0f0f0),
            child: InkWell(
              onTap: _copyCode,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      displayLanguage,
                      style: TextStyle(
                        fontSize: 12,
                        color: iconColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _copied
                        ? Icons.check_rounded
                        : Icons.copy_rounded,
                      size: 18,
                      color: _copied ? copiedColor : iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _copied ? 'Скопировано' : 'Копировать',
                      style: TextStyle(
                        fontSize: 12,
                        color: _copied ? copiedColor : iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SelectableText.rich(
              TextSpan(style: rootStyle, children: spans),
              style: rootStyle,
              enableInteractiveSelection: true,
              selectionControls: materialTextSelectionControls,
            ),
          ),
        ],
      ),
    );
  }
}
