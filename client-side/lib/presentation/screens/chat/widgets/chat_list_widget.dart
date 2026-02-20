import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/data/services/user_online_status_service.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_item.dart';

class ChatListWidget extends StatelessWidget {
  final ChatState state;

  const ChatListWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Чатов пока нет',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final onlineService = context.read<UserOnlineStatusService>();

    return StreamBuilder<Map<String, bool>>(
      stream: onlineService.statusStream,
      initialData: onlineService.statusMap,
      builder: (context, snapshot) {
        final statusMap = snapshot.data ?? {};
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: state.chats.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
          itemBuilder: (context, index) {
            final chat = state.chats[index];
            return ChatListItem(
              chat: chat,
              isSelected: chat == state.selectedChat,
              isOnline: statusMap[chat.userId] ?? false,
              onTap: () => context.read<ChatBloc>().add(ChatSelectChat(chat)),
            );
          },
        );
      },
    );
  }
}
