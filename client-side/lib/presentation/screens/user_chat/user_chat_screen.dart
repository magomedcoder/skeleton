import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/presentation/screens/user_chat/bloc/user_chat_bloc.dart';
import 'package:legion/presentation/screens/user_chat/bloc/user_chat_event.dart';
import 'package:legion/presentation/screens/user_chat/bloc/user_chat_state.dart';
import 'package:legion/presentation/screens/user_chat/chat_user_search_screen.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const ChatStarted());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(ChatSendMessage(text));
    _messageController.clear();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _buildChatList(ChatState state) {
    if (state.isLoading && state.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.chats.isEmpty) {
      return const Center(child: Text('Чатов пока нет'));
    }

    return ListView.builder(
      itemCount: state.chats.length,
      itemBuilder: (context, index) {
        final chat = state.chats[index];
        final isSelected = chat == state.selectedChat;
        return ListTile(
          selected: isSelected,
          title: Text(
            chat.userUsername.isNotEmpty
              ? chat.userUsername
              : '${chat.userName} ${chat.userSurname}',
          ),
          onTap: () {
            context.read<ChatBloc>().add(ChatSelectChat(chat));
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final alignment = Alignment.centerLeft;
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content, style: TextStyle(color: textColor)),
            const SizedBox(height: 2),
            Text(
              TimeOfDay.fromDateTime(message.createdAt).format(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatState state) {
    if (state.selectedChat == null) {
      return const Center(child: Text('Выберите чат слева'));
    }

    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return const Center(child: Text('Сообщений пока нет'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildInput(ChatState state) {
    final isEnabled = state.selectedChat != null && !state.isSending;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: isEnabled,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Напишите сообщение...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: state.isSending
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.send),
            onPressed: isEnabled ? _onSend : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChatBloc>().add(const ChatClearError());
        }
        if (state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      },
      builder: (context, state) {
        final isMobile = Breakpoints.isMobile(context);
        final body = Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    SizedBox(width: 260, child: _buildChatList(state)),
                  Expanded(child: _buildMessages(state)),
                ],
              ),
            ),
            _buildInput(state),
          ],
        );

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Личные чаты'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_search),
                  tooltip: 'Найти пользователя',
                  onPressed: () {
                    final chatBloc = context.read<ChatBloc>();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: chatBloc,
                          child: const ChatUserSearchScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: body,
            drawer: Drawer(child: SafeArea(child: _buildChatList(state))),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Личные чаты'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_search),
                tooltip: 'Найти пользователя',
                onPressed: () {
                  final chatBloc = context.read<ChatBloc>();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: chatBloc,
                        child: const ChatUserSearchScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}
