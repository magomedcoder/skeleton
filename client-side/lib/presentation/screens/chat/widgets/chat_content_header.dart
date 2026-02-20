import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/data/services/user_online_status_service.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_delete_scope_dialog.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_avatar.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_item.dart';

class ChatContentHeader extends StatelessWidget {
  final Chat? selectedChat;
  final bool showBackButton;
  final ChatState chatState;
  final int? currentUserId;

  const ChatContentHeader({
    super.key,
    required this.selectedChat,
    required this.chatState,
    this.currentUserId,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: showBackButton ? 4 : 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: chatState.isSelectionMode
        ? _buildSelectionHeader(context, theme)
        : selectedChat == null
          ? _buildEmptyHeader(context, theme)
          : _buildChatHeader(context, theme),
    );
  }

  Widget _buildSelectionHeader(BuildContext context, ThemeData theme) {
    final count = chatState.selectedMessageIds.length;
    final currentUserId = this.currentUserId;
    final myMessageIds = currentUserId != null
      ? chatState.messages
        .where((m) => m.senderId == currentUserId)
        .map((m) => m.id)
        .toSet()
      : <int>{};
    final allMySelected = myMessageIds.isNotEmpty 
      && myMessageIds.every((id) => chatState.selectedMessageIds.contains(id));
    final someMySelected = myMessageIds.any((id) => chatState.selectedMessageIds.contains(id));

    return Row(
      children: [
        if (showBackButton) const SizedBox(width: 48),
        if (myMessageIds.isNotEmpty)
          Checkbox(
            value: allMySelected ? true : (someMySelected ? null : false),
            tristate: true,
            onChanged: (value) {
              if (value == true) {
                context.read<ChatBloc>().add(const ChatSelectAllMyMessages());
              } else {
                context.read<ChatBloc>().add(const ChatClearSelection());
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        Expanded(
          child: Text(
            'Выбрано: $count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.read<ChatBloc>().add(const ChatClearSelection()),
          child: const Text('Отмена'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () async {
            final forEveryone = await showDeleteScopeDialog(context);
            if (context.mounted && forEveryone != null) {
              context.read<ChatBloc>().add(ChatDeleteSelectedMessages(
                forEveryone: forEveryone,
              ));
            }
          },
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Удалить'),
        ),
      ],
    );
  }

  Widget _buildEmptyHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (showBackButton) const SizedBox(width: 48),
        Expanded(
          child: Text(
            'Сообщения',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, ThemeData theme) {
    final chat = selectedChat!;
    final onlineService = context.read<UserOnlineStatusService>();
    final isOnline = onlineService.isOnline(chat.userId) ?? false;
    final title = ChatListItem.title(chat);

    return Row(
      children: [
        if (showBackButton)
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
    );
  }
}
