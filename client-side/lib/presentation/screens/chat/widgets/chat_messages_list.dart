import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_delete_scope_dialog.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_empty_placeholders.dart';
import 'package:legion/presentation/screens/chat/widgets/message_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final ChatState state;
  final ScrollController scrollController;

  const ChatMessagesList({
    super.key,
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (state.selectedChat == null) {
      return const ChatEmptyPlaceholder();
    }

    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return const ChatEmptyMessagesPlaceholder();
    }

    final currentUserId = context.read<AuthBloc>().state.user?.id;
    final currentUserInt = int.tryParse(currentUserId ?? '');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
      ? theme.colorScheme.surface
      : theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5);

    return Container(
      color: bgColor,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final isFromMe = currentUserInt != null && message.senderId == currentUserInt;
          final isSelected = state.selectedMessageIds.contains(message.id);
          return MessageBubble(
            message: message,
            isFromMe: isFromMe,
            onDelete: isFromMe
              ? () async {
                final forEveryone = await showDeleteScopeDialog(context);
                if (context.mounted && forEveryone != null) {
                  context.read<ChatBloc>().add(ChatDeleteMessage(
                    message,
                    forEveryone: forEveryone
                  ));
                }
              }
              : null,
            isSelectionMode: state.isSelectionMode,
            isSelected: isSelected,
            onToggleSelection: isFromMe
              ? () => context.read<ChatBloc>().add(ChatToggleMessageSelection(message))
              : null,
          );
        },
      ),
    );
  }
}
