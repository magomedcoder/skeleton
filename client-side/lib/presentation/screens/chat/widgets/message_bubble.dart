import 'package:flutter/material.dart';
import 'package:legion/core/date_formatter.dart';
import 'package:legion/domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: isFromMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFromMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isFromMe ? 18 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: isFromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                    child: Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isFromMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isFromMe
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
                        : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
