import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          : Theme.of(context).colorScheme.surfaceVariant,
      foregroundColor: _isComposing && widget.isEnabled
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
      shape: const CircleBorder(),
      child: const Icon(Icons.send, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
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
                          : 'Подключение...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _isComposing
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _textController.clear();
                                _focusNode.unfocus();
                              },
                            )
                          : null,
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
