import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/attachment_settings.dart';
import 'package:skeleton/core/layout/responsive.dart';
import 'package:skeleton/domain/entities/message.dart';
import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_event.dart';
import 'package:skeleton/presentation/screens/ai_chat/bloc/ai_chat_state.dart';
import 'package:skeleton/presentation/screens/ai_chat/widgets/chat_input_bar.dart';
import 'package:skeleton/presentation/widgets/chat_bubble.dart';

class ChatContent extends StatefulWidget {
  final VoidCallback? onOpenSessionsDrawer;
  final VoidCallback? onToggleSessionsSidebar;
  final bool? isSessionsSidebarVisible;

  const ChatContent({
    super.key,
    this.onOpenSessionsDrawer,
    this.onToggleSessionsSidebar,
    this.isSessionsSidebarVisible,
  });

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final _scrollController = ScrollController();
  final _inputBarKey = GlobalKey<ChatInputBarState>();
  bool _isDraggingFile = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _onFilesDropped(DropDoneDetails details) async {
    setState(() => _isDraggingFile = false);
    if (details.files.isEmpty) return;

    final item = details.files.first;
    if (item is! DropItemFile) return;
 
    try {
      final bytes = await item.readAsBytes();
      final name = item.name.isNotEmpty 
        ? item.name
        : item.path.split(RegExp(r'[/\\]')).last;
      if (!mounted) return;
      _inputBarKey.currentState?.setDroppedFile(
        PlatformFile(
          name: name,
          size: bytes.length,
          bytes: bytes,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось прочитать файл')),
        );
      }
    }
  }

  Widget _buildDropOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Отпустите файл, чтобы прикрепить',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Модель',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 15,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              selected ?? models.first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
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
          PopupMenuItem<String>(value: model, child: Text(model)),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.help_outline,
              size: 15,
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
        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
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

  Widget _buildChannelHeader(AIChatState state) {
    final theme = Theme.of(context);
    final currentSession = state.sessions.firstWhere(
      (session) => session.id == state.currentSessionId,
      orElse: () => ChatSession(
        id: '',
        title: 'Новый чат',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Breakpoints.isMobile(context) ? 12 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (widget.onOpenSessionsDrawer != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: widget.onOpenSessionsDrawer,
              tooltip: 'Сессии',
            ),
          if (widget.onToggleSessionsSidebar != null)
            Transform.translate(
              offset: const Offset(-12, 0),
              child: IconButton(
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                ),
                icon: Icon(
                  widget.isSessionsSidebarVisible == true
                      ? Icons.chevron_left_rounded
                      : Icons.list_rounded,
                ),
                onPressed: widget.onToggleSessionsSidebar,
                tooltip: widget.isSessionsSidebarVisible == true
                    ? 'Скрыть список сессий'
                    : 'Показать список сессий',
              ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSession.title,
                  style: theme.textTheme.titleMedium?.copyWith(
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
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Нет подключения',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  )
                else if (!(state.isLoading && !state.isStreaming))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _buildModelSelector(state),
                  ),
              ],
            ),
          ),
          if (state.isLoading && !state.isStreaming)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!(state.isLoading && !state.isStreaming))
            _buildSupportedFormatsButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoints.isMobile(context) ? 24 : 32,
          vertical: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Выберите сессию из списка слева\nили создайте новую',
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
    final horizontalPadding = Breakpoints.isMobile(context) ? 12.0 : 24.0;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: horizontalPadding,
      ),
      itemCount: state.messages.length + (state.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ChatBubble(message: state.messages[index]),
          );
        }
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
      },
    );
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
      child: BlocBuilder<AIChatBloc, AIChatState>(
        builder: (context, state) {
          if (state.isLoading && state.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final canDropFile = state.isConnected
              && !state.isLoading
              && (state.hasActiveRunners != false);
          return DropTarget(
            onDragEntered: canDropFile
              ? (_) => setState(() => _isDraggingFile = true)
              : null,
            onDragExited: canDropFile
              ? (_) => setState(() => _isDraggingFile = false)
              : null,
            onDragDone: canDropFile
              ? (details) => _onFilesDropped(details)
              : null,
            enable: canDropFile,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChannelHeader(state),
                    if (state.hasActiveRunners == false)
                      Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.errorContainer.withValues(alpha: 0.6),
                        child: SafeArea(
                          top: true,
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Нет активных раннеров',
                                    style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: state.messages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessageList(state),
                    ),
                    const Divider(height: 1),
                    ChatInputBar(
                      key: _inputBarKey,
                      isEnabled: canDropFile,
                    ),
                  ],
                ),
                if (_isDraggingFile)
                  _buildDropOverlay(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
