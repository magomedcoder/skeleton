import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/message.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
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
    final isUser = message.role == MessageRole.user;
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
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  enableInteractiveSelection: true,
                  selectionControls: materialTextSelectionControls,
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
