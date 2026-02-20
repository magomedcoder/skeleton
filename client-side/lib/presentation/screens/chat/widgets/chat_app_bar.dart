import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/data/services/user_online_status_service.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_avatar.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_item.dart';

class ChatAppBar extends StatelessWidget {
  final Chat chat;

  const ChatAppBar({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final onlineService = context.read<UserOnlineStatusService>();
    final isOnline = onlineService.isOnline(chat.userId) ?? false;
    final theme = Theme.of(context);
    final title = ChatListItem.title(chat);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: 4,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.read<ChatBloc>().add(const ChatBackToList()),
          ),
          ChatListAvatar(title: title, isOnline: isOnline, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'в сети' : 'не в сети',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOnline
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
