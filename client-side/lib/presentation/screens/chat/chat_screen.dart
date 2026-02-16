import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/chat_user_search_screen.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_widgets.dart';

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

  void _openUserSearch() {
    final chatBloc = context.read<ChatBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: chatBloc,
          child: const ChatUserSearchScreen(),
        ),
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
        final selectedChat = state.selectedChat;

        if (isMobile) {
          return Scaffold(
            appBar: selectedChat == null
                ? AppBar(
                    title: const Text('Чаты'),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_search_rounded),
                        tooltip: 'Найти пользователя',
                        onPressed: _openUserSearch,
                      ),
                    ],
                  )
                : null,
            body: selectedChat == null
                ? ChatListWidget(state: state)
                : Column(
                    children: [
                      ChatAppBar(chat: selectedChat),
                      Expanded(
                        child: ChatMessagesList(
                          state: state,
                          scrollController: _scrollController,
                        ),
                      ),
                      ChatInputBar(
                        controller: _messageController,
                        onSend: _onSend,
                        isEnabled: state.selectedChat != null && !state.isSending,
                        isSending: state.isSending,
                      ),
                    ],
                  ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Чаты'),
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_search_rounded),
                tooltip: 'Найти пользователя',
                onPressed: _openUserSearch,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: ChatListWidget(state: state),
                    ),
                    Expanded(
                      child: ChatMessagesList(
                        state: state,
                        scrollController: _scrollController,
                      ),
                    ),
                  ],
                ),
              ),
              ChatInputBar(
                controller: _messageController,
                onSend: _onSend,
                isEnabled: state.selectedChat != null && !state.isSending,
                isSending: state.isSending,
              ),
            ],
          ),
        );
      },
    );
  }
}
