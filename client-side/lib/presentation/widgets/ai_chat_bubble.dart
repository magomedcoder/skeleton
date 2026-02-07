import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeleton/core/layout/responsive.dart';
import 'package:skeleton/domain/entities/ai_message.dart';
import 'package:skeleton/presentation/widgets/code_block_builder.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatBubble extends StatefulWidget {
  final AIMessage message;
  final bool isStreaming;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _justCopied = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isStreaming = widget.isStreaming;
    final isUser = message.role == AIMessageRole.user;
    final theme = Theme.of(context);
    final width = Breakpoints.width(context);
    const minBubbleWidth = 64.0;
    final maxBubbleWidth = Breakpoints.isMobile(context)
      ? width * 0.85
      : (Breakpoints.isTablet(context) ? 400.0 : 500.0);
    final horizontalMargin = Breakpoints.isMobile(context) ? 4.0 : 16.0;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: horizontalMargin),
            padding: EdgeInsets.symmetric(
              horizontal: Breakpoints.isMobile(context) ? 12 : 16,
              vertical: Breakpoints.isMobile(context) ? 10 : 12,
            ),
            constraints: BoxConstraints(
              minWidth: minBubbleWidth,
              maxWidth: maxBubbleWidth,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.attachmentFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          size: 18,
                          color: isUser
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.attachmentFileName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.content.isNotEmpty)
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                      ),
                      listIndent: 24,
                      blockquote: TextStyle(
                        color: isUser
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isUser
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.5)
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            width: 4,
                          ),
                        ),
                      ),
                      code: TextStyle(
                        color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: (isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    builders: {
                      'pre': CodeBlockBuilder(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    },
                  ),
                if (isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            color: theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Обрабатываю...',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: horizontalMargin, right: horizontalMargin, bottom: 4),
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: message.content),
                );
                if (!mounted) return;
                setState(() => _justCopied = true);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _justCopied = false);
                });
              },
              icon: Icon(
                _justCopied ? Icons.check_rounded : Icons.copy_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(
                _justCopied ? 'Скопировано' : 'Копировать',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
