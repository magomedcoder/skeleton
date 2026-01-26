import 'package:flutter/material.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final width = Breakpoints.width(context);
    final maxBubbleWidth = Breakpoints.isMobile(context)
      ? width * 0.85
      : (Breakpoints.isTablet(context) ? 400.0 : 500.0);
    final horizontalMargin = Breakpoints.isMobile(context) ? 4.0 : 16.0;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: horizontalMargin),
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoints.isMobile(context) ? 12 : 16,
          vertical: Breakpoints.isMobile(context) ? 10 : 12,
        ),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
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
    );
  }
}
