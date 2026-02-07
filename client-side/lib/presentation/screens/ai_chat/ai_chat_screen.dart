import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/attachment_settings.dart';
import 'package:skeleton/core/layout/responsive.dart';
import 'package:skeleton/domain/entities/ai_message.dart';
import 'package:skeleton/domain/entities/ai_chat_session.dart';
import 'package:skeleton/core/injector.dart' as di;
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_bloc.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_event.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_state.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_event.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_state.dart';
import 'package:skeleton/presentation/screens/ai_chat/widgets/chat_input_bar.dart';
import 'package:skeleton/presentation/screens/ai_chat/widgets/sessions_sidebar.dart';
import 'package:skeleton/presentation/screens/profile/profile_screen.dart';
import 'package:skeleton/presentation/widgets/ai_chat_bubble.dart';
import 'package:skeleton/presentation/screens/admin/bloc/runners_admin_bloc.dart';
import 'package:skeleton/presentation/screens/admin/bloc/runners_admin_event.dart';
import 'package:skeleton/presentation/screens/admin/runners_admin_screen.dart';
import 'package:skeleton/presentation/screens/admin/users_admin_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = true;
  double get _sidebarWidth => Breakpoints.sidebarDefaultWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIChatBloc>().add(ChatStarted());
    });
  }

  void _scrollToBottom() {
    if (!mounted) return;

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final target = position.maxScrollExtent;

    if (position.pixels >= target) return;

    const threshold = 80.0;
    if (target - position.pixels <= threshold) {
      position.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
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

  void _createNewSession() {
    context.read<AIChatBloc>().add(const ChatCreateSession());
  }

  void _selectSession(AIChatSession session) {
    context.read<AIChatBloc>().add(ChatSelectSession(session.id));
  }

  void _selectSessionAndCloseDrawer(AIChatSession session) {
    _selectSession(session);
    if (Breakpoints.useDrawerForSessions(context)) {
      Navigator.of(context).pop();
    }
  }

  void _deleteSession(String sessionId, String sessionTitle) {
    final chatBloc = context.read<AIChatBloc>();
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

  Widget _buildModelSelector(AIChatState state) {
    final theme = Theme.of(context);
    final models = state.models;
    final selected = state.selectedModel;
    final isEnabled = state.isConnected && !state.isLoading;

    if (models.isEmpty) {
      return Tooltip(
        message: 'Модели не загружены',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 5),
              Text(
                'Модель',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      enabled: isEnabled,
      tooltip: 'Выбор модели',
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 14,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              selected ?? models.first,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
      onOpened: () {
        if (state.models.isEmpty) {
          context.read<AIChatBloc>().add(const ChatLoadModels());
        }
      },
      itemBuilder: (context) => [
        for (final model in models)
          PopupMenuItem<String>(
            value: model,
            child: Text(model),
          ),
      ],
      onSelected: (value) {
        context.read<AIChatBloc>().add(ChatSelectModel(value));
      },
    );
  }

  Widget _buildSupportedFormatsButton() {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Поддерживаемые форматы вложений',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showSupportedFormatsDialog,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.help_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportedFormatsDialog() {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile
      ? MediaQuery.sizeOf(context).width - 32
      : 400.0;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              color: theme.colorScheme.primary,
              size: isMobile ? 22 : 24,
            ),
            SizedBox(width: isMobile ? 8 : 10),
            Flexible(
              child: Text(
                'Поддерживаемые форматы',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Текст',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AttachmentSettings.textFormatLabels.join(', '),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Документы',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AttachmentSettings.documentFormatLabels.join(', '),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Макс. размер: ${AttachmentSettings.maxFileSizeKb} КБ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(AIChatState state) {
    final useDrawer = Breakpoints.useDrawerForSessions(context);
    final currentSession = state.sessions.firstWhere(
      (session) => session.id == state.currentSessionId,
      orElse: () => AIChatSession(
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

  Widget _buildMessageList(AIChatState state) {
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
              message: AIMessage(
                id: 'streaming',
                content: state.currentStreamingText ?? '',
                role: AIMessageRole.assistant,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AIChatBloc, AIChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToBottom();
          });
        }

        if (state.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
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
              title: BlocBuilder<AIChatBloc, AIChatState>(
                builder: (context, state) => _buildAppBarTitle(state),
              ),
              actions: [
                BlocBuilder<AIChatBloc, AIChatState>(
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

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.dns_outlined),
                          tooltip: 'Раннеры (админ)',
                          onPressed: () {
                            final authBloc = context.read<AuthBloc>();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: authBloc),
                                    BlocProvider(
                                      create: (_) => di.sl<RunnersAdminBloc>()
                                        ..add(const RunnersAdminLoadRequested()),
                                    ),
                                  ],
                                  child: const RunnersAdminScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
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
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              bottom: true,
              left: false,
              right: false,
              child: Row(
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
                  child: BlocBuilder<AIChatBloc, AIChatState>(
                    builder: (context, state) {
                      if (state.isLoading && state.messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: [
                          if (state.hasActiveRunners == false)
                            Material(
                              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.6),
                              child: SafeArea(
                                top: true,
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Нет активных раннеров',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Breakpoints.isMobile(context) ? 12 : 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildModelSelector(state),
                                const Spacer(),
                                _buildSupportedFormatsButton(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: state.messages.isEmpty
                              ? _buildEmptyChatState()
                              : _buildMessageList(state),
                          ),
                          const Divider(height: 1),
                          ChatInputBar(isEnabled: state.isConnected
                            && !state.isLoading
                            && (state.hasActiveRunners != false),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
