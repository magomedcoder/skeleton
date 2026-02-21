import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/message_deleted_payload.dart';
import 'package:legion/domain/entities/message_read_payload.dart';
import 'package:legion/domain/usecases/chat/create_chat_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chats_usecase.dart';
import 'package:legion/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;
  final CreateChatUseCase createChatUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final DeleteChatMessagesUseCase deleteChatMessagesUseCase;
  final AuthBloc authBloc;
  StreamSubscription<Message>? _newMessageSubscription;
  StreamSubscription<MessageDeletedPayload>? _messageDeletedSubscription;
  StreamSubscription<MessageReadPayload>? _messageReadSubscription;

  ChatBloc({
    required this.getChatsUseCase,
    required this.createChatUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.deleteChatMessagesUseCase,
    required this.authBloc,
    Stream<Message>? newMessageStream,
    Stream<MessageDeletedPayload>? messageDeletedStream,
    Stream<MessageReadPayload>? messageReadStream,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearError>(_onClearError);
    on<ChatBackToList>(_onBackToList);
    on<ChatNewMessageReceived>(_onNewMessageReceived);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatToggleMessageSelection>(_onToggleMessageSelection);
    on<ChatDeleteSelectedMessages>(_onDeleteSelectedMessages);
    on<ChatClearSelection>(_onClearSelection);
    on<ChatSelectAllMyMessages>(_onSelectAllMyMessages);
    on<ChatMessagesDeletedFromServer>(_onMessagesDeletedFromServer);
    on<ChatMessagesRead>(_onMessagesRead);

    if (newMessageStream != null) {
      _newMessageSubscription = newMessageStream.listen((message) {
        add(ChatNewMessageReceived(message));
      });
    }
    if (messageDeletedStream != null) {
      _messageDeletedSubscription = messageDeletedStream.listen((payload) {
        add(ChatMessagesDeletedFromServer(
          peerId: payload.peerId,
          fromPeerId: payload.fromPeerId,
          messageIds: payload.messageIds,
        ));
      });
    }
    if (messageReadStream != null) {
      _messageReadSubscription = messageReadStream.listen((payload) {
        add(ChatMessagesRead(
          readerUserId: payload.readerUserId,
          peerUserId: payload.peerUserId,
          lastReadMessageId: payload.lastReadMessageId,
        ));
      });
    }
  }

  @override
  Future<void> close() {
    _newMessageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReadSubscription?.cancel();
    return super.close();
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearSelectedChat: true, clearSelection: true));
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
        clearSelection: true,
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

      final updatedChats = state.chats
        .map((c) => c.userId == chat.userId ? c.copyWith(unreadCount: 0) : c)
        .toList();
      emit(state.copyWith(
        messages: messages,
        isLoading: false,
        chats: updatedChats,
      ));
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
    if (currentUserId == null) {
      return;
    }

    final isInOpenChat = selectedChat != null && message.isInDialog(currentUserId, int.parse(selectedChat.userId));

    if (isInOpenChat) {
      if (state.messages.any((m) => m.id == message.id)) {
        return;
      }
      emit(state.copyWith(messages: [...state.messages, message]));
      Logs().d('ChatBloc: добавлено новое сообщение в диалог');
      return;
    }

    final otherUserId = message.peerUserId == currentUserId
      ? message.fromPeerUserId
      : message.peerUserId;
    final otherUserIdStr = otherUserId.toString();
    if (!state.chats.any((c) => c.userId == otherUserIdStr)) {
      return;
    }

    final updatedChats = state.chats.map((c) {
      if (c.userId != otherUserIdStr) {
        return c;
      }

      return c.copyWith(unreadCount: c.unreadCount + 1);
    }).toList();

    emit(state.copyWith(chats: updatedChats));
  }

  Future<void> _onDeleteMessage(
    ChatDeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message;
    final chat = state.selectedChat;
    if (chat == null) return;

    emit(state.copyWith(error: null));
    try {
      await deleteChatMessagesUseCase(
        [message.id], 
        forEveryone: event.forEveryone,
      );
      final updated = state.messages.where((m) => m.id != message.id).toList();
      emit(state.copyWith(messages: updated));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления сообщения', e);
      emit(state.copyWith(error: 'Ошибка удаления сообщения'));
    }
  }

  void _onToggleMessageSelection(
    ChatToggleMessageSelection event,
    Emitter<ChatState> emit,
  ) {
    final id = event.message.id;
    final next = Set<int>.from(state.selectedMessageIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    emit(state.copyWith(selectedMessageIds: next));
  }

  Future<void> _onDeleteSelectedMessages(
    ChatDeleteSelectedMessages event,
    Emitter<ChatState> emit,
  ) async {
    final ids = state.selectedMessageIds.toList();
    if (ids.isEmpty) return;

    emit(state.copyWith(error: null));
    try {
      await deleteChatMessagesUseCase(
        ids,
        forEveryone: event.forEveryone,
      );
      final idSet = state.selectedMessageIds;
      final updated = state.messages.where((m) => !idSet.contains(m.id)).toList();
      emit(state.copyWith(messages: updated, clearSelection: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления сообщений', e);
      emit(state.copyWith(error: 'Ошибка удаления сообщений'));
    }
  }

  void _onClearSelection(ChatClearSelection event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearSelection: true));
  }

  void _onSelectAllMyMessages(
    ChatSelectAllMyMessages event,
    Emitter<ChatState> emit,
  ) {
    final currentUserId = int.tryParse(authBloc.state.user?.id ?? '');
    if (currentUserId == null) return;
    final myIds = state.messages.where((m) => m.senderId == currentUserId)
      .map((m) => m.id)
      .toSet();
    emit(state.copyWith(selectedMessageIds: myIds));
  }

  void _onMessagesDeletedFromServer(
    ChatMessagesDeletedFromServer event,
    Emitter<ChatState> emit,
  ) {
    final selectedChat = state.selectedChat;
    if (selectedChat == null) {
      return;
    }

    final currentUserId = int.tryParse(authBloc.state.user?.id ?? '');
    if (currentUserId == null) {
      return;
    }

    final otherUserId = int.parse(selectedChat.userId);
    final isThisDialog = (event.peerId == currentUserId && event.fromPeerId == otherUserId) || (event.peerId == otherUserId && event.fromPeerId == currentUserId);
    if (!isThisDialog) {
      return;
    }

    final idSet = event.messageIds.toSet();
    final updatedMessages = state.messages.where((m) => !idSet.contains(m.id)).toList();
    final updatedSelection = state.selectedMessageIds.difference(idSet);
    emit(state.copyWith(
      messages: updatedMessages,
      selectedMessageIds: updatedSelection,
    ));
    Logs().d('ChatBloc: удалены сообщения с сервера ids=$idSet');
  }

  void _onMessagesRead(ChatMessagesRead event, Emitter<ChatState> emit) {
    final currentUserId = int.tryParse(authBloc.state.user?.id ?? '');
    if (currentUserId == null) {
      return;
    }

    if (event.peerUserId != currentUserId) {
      return;
    }

    final selectedChat = state.selectedChat;
    if (selectedChat == null) {
      return;
    }

    if (selectedChat.userId != event.readerUserId.toString()) {
      return;
    }

    final updatedMessages = state.messages.map((m) {
      if (m.senderId == currentUserId && m.id <= event.lastReadMessageId && !m.isRead) {
        return m.copyWith(isRead: true);
      }

      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
    Logs().d('ChatBloc: сообщения прочитаны до id=${event.lastReadMessageId}');
  }
}
