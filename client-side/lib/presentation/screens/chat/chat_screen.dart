import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_widgets.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showUserSearch = false;

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
    setState(() => _showUserSearch = true);
  }

  void _closeUserSearch() {
    setState(() => _showUserSearch = false);
  }

  void _onSearchUserSelected(User user) {
    context.read<ChatBloc>().add(ChatOpenWithUser(user.id));
    setState(() => _showUserSearch = false);
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
                title: Text(_showUserSearch ? 'Найти пользователя' : 'Чаты'),
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: _showUserSearch
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _closeUserSearch,
                  )
                : null,
                actions: _showUserSearch
                  ? null
                  : [
                    IconButton(
                      icon: const Icon(Icons.person_search_rounded),
                      tooltip: 'Найти пользователя',
                      onPressed: _openUserSearch,
                    ),
                  ],
              )
              : null,
            body: selectedChat == null
              ? _showUserSearch
                ? ChatUserSearchPanel(
                    onUserSelected: _onSearchUserSelected,
                    onClose: _closeUserSearch,
                  )
                : ChatListWidget(state: state)
              : Column(
                children: [
                  ChatContentHeader(
                    selectedChat: selectedChat,
                    chatState: state,
                    currentUserId: int.tryParse(context.read<AuthBloc>().state.user?.id ?? ''),
                    showBackButton: true,
                  ),
                  Expanded(
                    child: ChatMessagesList(
                      state: state,
                      scrollController: _scrollController,
                    ),
                  ),
                  if (!state.isSelectionMode)
                    ChatInputBar(
                      controller: _messageController,
                      onSend: _onSend,
                      isEnabled: selectedChat != null && !state.isSending,
                      isSending: state.isSending,
                    ),
                ],
              ),
          );
        }

        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ChatListPanelHeader(
                      isSearchMode: _showUserSearch,
                      onSearch: _openUserSearch,
                      onCloseSearch: _closeUserSearch,
                    ),
                    Expanded(
                      child: _showUserSearch
                        ? ChatUserSearchPanel(
                          onUserSelected: _onSearchUserSelected,
                          onClose: _closeUserSearch,
                        )
                      : ChatListWidget(state: state),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChatContentHeader(
                        selectedChat: selectedChat,
                        chatState: state,
                        currentUserId: int.tryParse(context.read<AuthBloc>().state.user?.id ?? ''),
                        showBackButton: false,
                      ),
                      Expanded(
                        child: ChatMessagesList(
                          state: state,
                          scrollController: _scrollController,
                        ),
                      ),
                      if (selectedChat != null && !state.isSelectionMode)
                        ChatInputBar(
                          controller: _messageController,
                          onSend: _onSend,
                          isEnabled: !state.isSending,
                          isSending: state.isSending,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatListPanelHeader extends StatelessWidget {
  final bool isSearchMode;
  final VoidCallback onSearch;
  final VoidCallback onCloseSearch;

  const _ChatListPanelHeader({
    required this.isSearchMode,
    required this.onSearch,
    required this.onCloseSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
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
          if (isSearchMode)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'К списку чатов',
              onPressed: onCloseSearch,
            ),
          Text(
            isSearchMode ? 'Найти пользователя' : 'Чаты',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (!isSearchMode)
            IconButton(
              icon: const Icon(Icons.person_search_rounded),
              tooltip: 'Найти пользователя',
              onPressed: onSearch,
            ),
        ],
      ),
    );
  }
}
