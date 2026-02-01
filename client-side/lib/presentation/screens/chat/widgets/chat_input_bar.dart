import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/attachment_settings.dart';
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
  PlatformFile? _selectedFile;

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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final hasFile = _selectedFile != null;

    if (!text.isNotEmpty && !hasFile) return;

    if (hasFile) {
      final file = _selectedFile!;
      Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось прочитать файл. Попробуйте снова.'),
            ),
          );
        }
        return;
      }
      if (bytes.length > AttachmentSettings.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Файл слишком большой (макс. ${AttachmentSettings.maxFileSizeKb} КБ)',
              ),
            ),
          );
        }
        return;
      }
      try {
        utf8.decode(bytes);
      } on FormatException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Поддерживаются только текстовые файлы (UTF-8)',
              ),
            ),
          );
        }
        return;
      }
    }

    context.read<ChatBloc>().add(
      ChatSendMessage(
        text,
        attachmentFileName: hasFile ? _selectedFile!.name : null,
        attachmentContent: hasFile ? _selectedFile!.bytes : null,
      ),
    );
    _textController.clear();
    _focusNode.unfocus();
    setState(() => _selectedFile = null);
  }

  void _stopGeneration() {
    context.read<ChatBloc>().add(const ChatStopGeneration());
  }

  Future<void> _pickFile() async {
    if (!widget.isEnabled) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AttachmentSettings.textFileExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить содержимое файла'),
          ),
        );
      }
      return;
    }
    if (file.bytes!.length > AttachmentSettings.maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Файл слишком большой (макс. ${AttachmentSettings.maxFileSizeKb} КБ)',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _selectedFile = file);
  }

  void _clearFile() {
    setState(() => _selectedFile = null);
  }

  String _fileName(PlatformFile file) {
    return file.name;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildFileButton() {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Прикрепить файл',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.attach_file_rounded,
              size: 22,
              color: widget.isEnabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(ChatState state) {
    final theme = Theme.of(context);
    if (state.isStreaming) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _stopGeneration,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.stop_rounded,
              size: 22,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }

    final canSend = (_isComposing || _selectedFile != null) && widget.isEnabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSend ? _sendMessage : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: canSend
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.send_rounded,
            size: 22,
            color: canSend
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Breakpoints.isMobile(context) ? 12.0 : 20.0;
    final theme = Theme.of(context);

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedFile != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName(_selectedFile!),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFileButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Shortcuts(
                        shortcuts: const <ShortcutActivator, Intent>{
                          SingleActivator(LogicalKeyboardKey.enter): _SendMessageIntent(),
                        },
                        child: Actions(
                          actions: <Type, Action<Intent>>{
                            _SendMessageIntent: CallbackAction<_SendMessageIntent>(
                              onInvoke: (_) {
                                _sendMessage();
                                return null;
                              },
                            ),
                          },
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 6,
                            enabled: widget.isEnabled,
                            style: TextStyle(
                              fontSize: 15,
                              color: widget.isEnabled
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.isEnabled
                                  ? 'Напишите сообщение...'
                                  : 'Обрабатываю...',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            textInputAction: TextInputAction.newline,
                            onSubmitted: (_) => _sendMessage(),
                            onTapOutside: (_) => _focusNode.unfocus(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildSendButton(state),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}
