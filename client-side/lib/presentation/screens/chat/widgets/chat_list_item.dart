import 'package:flutter/material.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_avatar.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final bool isOnline;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.isOnline,
    required this.onTap,
  });

  static String title(Chat chat) {
    if (chat.userUsername.isNotEmpty) return chat.userUsername;
    return '${chat.userName} ${chat.userSurname}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStr = title(chat);

    return Material(
      color: isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
        : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ChatListAvatar(title: titleStr, isOnline: isOnline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline ? 'В сети' : 'Не в сети',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
