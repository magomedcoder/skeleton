import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/ai_chat_session.dart';
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_event.dart';
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_state.dart';

typedef ChatSessionCallback = void Function(AIChatSession);

class SessionsSidebar extends StatefulWidget {
  final VoidCallback onCreateNewSession;
  final ChatSessionCallback onSelectSession;
  final void Function(String id, String title) onDeleteSession;
  final bool isInDrawer;

  const SessionsSidebar({
    super.key,
    required this.onCreateNewSession,
    required this.onSelectSession,
    required this.onDeleteSession,
    this.isInDrawer = false,
  });

  @override
  State<SessionsSidebar> createState() => _SessionsSidebarState();
}

class _SessionsSidebarState extends State<SessionsSidebar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSessions() {
    context.read<AIChatBloc>().add(ChatLoadSessions());
  }

  Widget _buildSessionItem(AIChatSession session, AIChatState state) {
    final isSelected = state.currentSessionId == session.id;
    final isDesktop = Breakpoints.isDesktop(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onSecondaryTapDown: isDesktop
                ? (TapDownDetails details) =>
                    _showSessionContextMenuDesktop(session, details)
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onSelectSession(session),
              onLongPress: () => _showSessionContextMenu(session, context),
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _showSessionContextMenuDesktop(
      AIChatSession session,
    TapDownDetails details,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      screenSize.width - details.globalPosition.dx,
      screenSize.height - details.globalPosition.dy,
    );
    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Редактировать название'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              Text(
                'Удалить',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') _showEditDialog(session);
      if (value == 'delete') widget.onDeleteSession(session.id, session.title);
    });
  }

  void _showSessionContextMenu(AIChatSession session, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Редактировать название'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(session);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Удалить',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDeleteSession(session.id, session.title);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(AIChatSession session) {
    final chatBloc = context.read<AIChatBloc>();
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать название'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите новое название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty && title != session.title) {
                chatBloc.add(
                  ChatUpdateSessionTitle(session.id, title),
                );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 54,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'История пуста',
              style: Theme.of(context).textTheme.titleMedium,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка сессий...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    if (!widget.isInDrawer) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        8,
        12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Сессии',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final padding = widget.isInDrawer && Breakpoints.isMobile(context)
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.all(16);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Новый чат'),
        onPressed: widget.onCreateNewSession,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: BlocBuilder<AIChatBloc, AIChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return _buildLoadingState();
                }

                if (state.error != null) {
                  return _buildErrorState();
                }

                if (state.sessions.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadSessions();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      return _buildSessionItem(session, state);
                    },
                  ),
                );
              },
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }
}
