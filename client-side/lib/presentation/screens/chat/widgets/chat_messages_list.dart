import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
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

    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final isFromMe = currentUserInt != null && message.senderId == currentUserInt;
          return MessageBubble(message: message, isFromMe: isFromMe);
        },
      ),
    );
  }
}
