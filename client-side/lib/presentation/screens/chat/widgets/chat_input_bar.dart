import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';

class ChatInputBar extends StatefulWidget {
  final bool isEnabled;

  const ChatInputBar({super.key, required this.isEnabled});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _textController.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
      ChatSendMessage(text),
    );
    _textController.clear();
    _focusNode.unfocus();
  }

  void _stopGeneration() {
    context.read<ChatBloc>().add(const ChatStopGeneration());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildModelSelector(ChatState state) {
    final models = state.models;
    final selected = state.selectedModel;
    if (models.isEmpty) {
      return Tooltip(
        message: 'Модели не загружены',
        child: Icon(
          Icons.smart_toy_outlined,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: PopupMenuButton<String>(
        enabled: widget.isEnabled,
        tooltip: 'Выбор модели',
        padding: EdgeInsets.zero,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 22,
              color: widget.isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                selected ?? models.first,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isEnabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onOpened: () {
          if (state.models.isEmpty) {
            context.read<ChatBloc>().add(const ChatLoadModels());
          }
        },
        itemBuilder: (context) => [
          for (final model in models)
            PopupMenuItem<String>(
              value: model,
              child: Text(model, overflow: TextOverflow.ellipsis),
            ),
        ],
        onSelected: (value) {
          context.read<ChatBloc>().add(ChatSelectModel(value));
        },
      ),
    );
  }

  Widget _buildSendButton(ChatState state) {
    if (state.isStreaming) {
      return FloatingActionButton.small(
        onPressed: _stopGeneration,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.stop, size: 20),
      );
    }

    return FloatingActionButton.small(
      onPressed: _isComposing && widget.isEnabled ? _sendMessage : null,
      backgroundColor: _isComposing && widget.isEnabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: _isComposing && widget.isEnabled
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: const Icon(Icons.send, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Breakpoints.isMobile(context) ? 12.0 : 16.0;
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildModelSelector(state),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    enabled: widget.isEnabled,
                    style: TextStyle(
                      color: widget.isEnabled
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isEnabled
                          ? 'Напишите сообщение...'
                          : 'Обрабатываю...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onTapOutside: (_) => _focusNode.unfocus(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildSendButton(state),
            ],
          ),
        );
      },
    );
  }
}
