import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearError>(_onClearError);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    await _loadChatsInternal(emit, page: 1, pageSize: 50);
  }

  Future<void> _onLoadChats(
    ChatLoadChats event,
    Emitter<ChatState> emit,
  ) async {
    await _loadChatsInternal(emit, page: event.page, pageSize: event.pageSize);
  }

  Future<void> _loadChatsInternal(
    Emitter<ChatState> emit, {
    required int page,
    required int pageSize,
  }) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final chats = await repository.getChats(page: page, pageSize: pageSize);
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
      final chat = await repository.createChat(event.userId);
      final chats = await repository.getChats(page: 1, pageSize: 50);
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
      final messages = await repository.getMessages(
        chatId: chat.id,
        page: 1,
        pageSize: 100,
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
      final message = await repository.sendMessage(
        chatId: chat.id,
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
}
