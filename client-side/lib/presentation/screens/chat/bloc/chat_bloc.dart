import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/usecases/chat/create_chat_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chats_usecase.dart';
import 'package:legion/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;
  final CreateChatUseCase createChatUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final AuthBloc authBloc;
  StreamSubscription<Message>? _newMessageSubscription;

  ChatBloc({
    required this.getChatsUseCase,
    required this.createChatUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.authBloc,
    Stream<Message>? newMessageStream,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearError>(_onClearError);
    on<ChatBackToList>(_onBackToList);
    on<ChatNewMessageReceived>(_onNewMessageReceived);

    if (newMessageStream != null) {
      _newMessageSubscription = newMessageStream.listen((message) {
        add(ChatNewMessageReceived(message));
      });
    }
  }

  @override
  Future<void> close() {
    _newMessageSubscription?.cancel();
    return super.close();
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearSelectedChat: true));
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    await _loadChatsInternal(emit);
  }

  Future<void> _onLoadChats(
    ChatLoadChats event,
    Emitter<ChatState> emit,
  ) async {
    await _loadChatsInternal(emit);
  }

  Future<void> _loadChatsInternal(Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final chats = await getChatsUseCase();
      emit(state.copyWith(isLoading: false, chats: chats, error: null));
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки чатов', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка загрузки чатов'));
    }
  }

  Future<void> _onOpenWithUser(
    ChatOpenWithUser event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final chat = await createChatUseCase(event.userId);
      final chats = await getChatsUseCase();
      emit(state.copyWith(isLoading: false, chats: chats, selectedChat: chat));
      await _loadMessagesForChat(chat, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка открытия чата с пользователем', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка открытия чата'));
    }
  }

  Future<void> _onSelectChat(
    ChatSelectChat event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedChat: event.chat,
        messages: const [],
        isLoading: true,
        error: null,
      ),
    );
    await _loadMessagesForChat(event.chat, emit);
  }

  Future<void> _loadMessagesForChat(Chat chat, Emitter<ChatState> emit) async {
    try {
      final peerUserId = int.parse(chat.userId);
      final messages = await getChatMessagesUseCase(
        peerUserId: peerUserId,
        messageId: 0,
        limit: 100,
      );
      emit(state.copyWith(messages: messages, isLoading: false));
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений', e);
      emit(
        state.copyWith(isLoading: false, error: 'Ошибка загрузки сообщений'),
      );
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final chat = state.selectedChat;
    if (chat == null) {
      emit(state.copyWith(error: 'Чат не выбран'));
      return;
    }

    emit(state.copyWith(isSending: true, error: null));
    try {
      final message = await sendChatMessageUseCase(
        peerUserId: int.parse(chat.userId),
        content: text,
      );
      final updatedMessages = [...state.messages, message];
      emit(state.copyWith(isSending: false, messages: updatedMessages));
    } catch (e) {
      Logs().e('ChatBloc: ошибка отправки сообщения', e);
      emit(
        state.copyWith(isSending: false, error: 'Ошибка отправки сообщения'),
      );
    }
  }

  void _onClearError(ChatClearError event, Emitter<ChatState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onNewMessageReceived(
    ChatNewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;
    final selectedChat = state.selectedChat;
    final currentUserId = int.tryParse(authBloc.state.user?.id ?? '');
    if (selectedChat != null &&
        currentUserId != null &&
        message.isInDialog(currentUserId, int.parse(selectedChat.userId))) {
      if (state.messages.any((m) => m.id == message.id)) {
        return;
      }

      emit(state.copyWith(messages: [...state.messages, message]));
      Logs().d('ChatBloc: добавлено новое сообщение в диалог');
    }
  }
}
