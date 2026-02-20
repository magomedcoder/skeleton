import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';

class ChatState extends Equatable {
  final bool isLoading;
  final bool isSending;
  final List<Chat> chats;
  final Chat? selectedChat;
  final List<Message> messages;
  final Set<int> selectedMessageIds;
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.chats = const [],
    this.selectedChat,
    this.messages = const [],
    this.selectedMessageIds = const {},
    this.error,
  });

  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    List<Chat>? chats,
    Chat? selectedChat,
    bool clearSelectedChat = false,
    List<Message>? messages,
    Set<int>? selectedMessageIds,
    bool clearSelection = false,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      chats: chats ?? this.chats,
      selectedChat: clearSelectedChat
        ? null
        : (selectedChat ?? this.selectedChat),
      messages: messages ?? this.messages,
      selectedMessageIds: clearSelection
        ? const {}
        : (selectedMessageIds ?? this.selectedMessageIds),
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSending,
    chats,
    selectedChat,
    messages,
    selectedMessageIds,
    error,
  ];
}
