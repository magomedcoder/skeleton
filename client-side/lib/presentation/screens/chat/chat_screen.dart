import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/presentation/screens/admin/bloc/users_admin_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_event.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_input_bar.dart';
import 'package:legion/presentation/screens/chat/widgets/sessions_sidebar.dart';
import 'package:legion/presentation/screens/profile/profile_screen.dart';
import 'package:legion/presentation/widgets/chat_bubble.dart';
import 'package:legion/presentation/screens/admin/users_admin_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _sessionTitleController = TextEditingController();
  bool _isEditingTitle = false;
  bool _isSidebarExpanded = true;
  double get _sidebarWidth => Breakpoints.sidebarDefaultWidth;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(ChatStarted());
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _createNewSession() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая сессия'),
        content: TextField(
          controller: _sessionTitleController,
          decoration: const InputDecoration(
            hintText: 'Введите название сессии',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _sessionTitleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result != null) {
      context.read<ChatBloc>().add(ChatCreateSession(title: result));
      _sessionTitleController.clear();
    }
  }

  void _selectSession(ChatSession session) {
    context.read<ChatBloc>().add(ChatSelectSession(session.id));
  }

  void _selectSessionAndCloseDrawer(ChatSession session) {
    _selectSession(session);
    if (Breakpoints.useDrawerForSessions(context)) {
      Navigator.of(context).pop();
    }
  }

  void _deleteSession(String sessionId, String sessionTitle) {
    final chatBloc = context.read<ChatBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить сессию?'),
        content: Text('Вы уверены, что хотите удалить сессию "$sessionTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              chatBloc.add(ChatDeleteSession(sessionId));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startEditingTitle(ChatSession session) {
    _sessionTitleController.text = session.title;
    _isEditingTitle = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать название'),
        content: TextField(
          controller: _sessionTitleController,
          decoration: const InputDecoration(
            hintText: 'Введите новое название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isEditingTitle = false;
              _sessionTitleController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _sessionTitleController.text.trim();
              if (title.isNotEmpty && title != session.title) {
                context.read<ChatBloc>().add(
                  ChatUpdateSessionTitle(session.id, title),
                );
              }
              _isEditingTitle = false;
              _sessionTitleController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(ChatState state) {
    final useDrawer = Breakpoints.useDrawerForSessions(context);
    final currentSession = state.sessions.firstWhere(
      (session) => session.id == state.currentSessionId,
      orElse: () => ChatSession(
        id: '',
        title: 'Новый чат',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Row(
      children: [
        if (!useDrawer)
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: _toggleSidebar,
            tooltip: _isSidebarExpanded ? 'Скрыть меню' : 'Показать меню',
          ),
        if (!useDrawer)
          const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentSession.title,
                style: TextStyle(
                  fontSize: useDrawer ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!state.isConnected)
                Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Нет подключения',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChatState() {
    final useDrawer = Breakpoints.useDrawerForSessions(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoints.isMobile(context) ? 24 : 32,
          vertical: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Icon(
                Icons.chat_bubble_outline,
                size: 54,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(useDrawer
              ? 'Нажмите ☰ чтобы выбрать сессию\nили создайте новую'
              : 'Выберите сессию из списка слева\nили создайте новую',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    final horizontalPadding =
        Breakpoints.isMobile(context) ? 12.0 : 16.0;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: horizontalPadding),
      itemCount: state.messages.length + (state.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ChatBubble(message: state.messages[index]),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ChatBubble(
              message: Message(
                id: 'streaming',
                content: state.currentStreamingText ?? '',
                role: MessageRole.assistant,
                createdAt: DateTime.now(),
              ),
              isStreaming: true,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sessionTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && state.messages.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (state.error != null && !_isEditingTitle) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          });
        }
      },
      child: Builder(
        builder: (context) {
          final useDrawer = Breakpoints.useDrawerForSessions(context);
          return Scaffold(
            key: _scaffoldKey,
            drawer: useDrawer
                ? Drawer(
                    child: SafeArea(
                      child: SessionsSidebar(
                        isInDrawer: true,
                        onCreateNewSession: _createNewSession,
                        onSelectSession: _selectSessionAndCloseDrawer,
                        onDeleteSession: _deleteSession,
                      ),
                    ),
                  )
                : null,
            appBar: AppBar(
              leading: useDrawer
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Меню сессий',
                  )
                : null,
              title: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) => _buildAppBarTitle(state),
              ),
              actions: [
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.isLoading && !state.isStreaming) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Профиль',
                  onPressed: () {
                    final authBloc = context.read<AuthBloc>();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: authBloc,
                          child: const ProfileScreen(),
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState.user;
                    final isAdmin = user?.isAdmin ?? false;

                    if (!isAdmin) return const SizedBox.shrink();

                    return IconButton(
                      icon: const Icon(Icons.supervisor_account_outlined),
                      tooltip: 'Пользователи (админ)',
                      onPressed: () {
                        final authBloc = context.read<AuthBloc>();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(value: authBloc),
                                BlocProvider(
                                  create: (_) => di.sl<UsersAdminBloc>()
                                    ..add(const UsersAdminLoadRequested()),
                                ),
                              ],
                              child: const UsersAdminScreen(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            body: Row(
              children: [
                if (!useDrawer)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isSidebarExpanded ? _sidebarWidth : 0,
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isSidebarExpanded
                        ? SessionsSidebar(
                            onCreateNewSession: _createNewSession,
                            onSelectSession: _selectSession,
                            onDeleteSession: _deleteSession,
                          )
                        : const SizedBox.shrink(),
                  ),
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state.isLoading && state.messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: state.messages.isEmpty
                                ? _buildEmptyChatState()
                                : _buildMessageList(state),
                          ),
                          const Divider(height: 1),
                          ChatInputBar(isEnabled: state.isConnected && !state.isLoading),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
