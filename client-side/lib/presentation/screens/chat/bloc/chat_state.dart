import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final bool isConnected;
  final bool isLoading;
  final bool isStreaming;
  final String? currentSessionId;
  final List<ChatSession> sessions;
  final List<Message> messages;
  final String? currentStreamingText;
  final String? error;
  final List<String> models;
  final String? selectedModel;

  const ChatState({
    this.isConnected = false,
    this.isLoading = false,
    this.isStreaming = false,
    this.currentSessionId,
    this.sessions = const [],
    this.messages = const [],
    this.currentStreamingText,
    this.error,
    this.models = const [],
    this.selectedModel,
  });

  ChatState copyWith({
    bool? isConnected,
    bool? isLoading,
    bool? isStreaming,
    String? currentSessionId,
    List<ChatSession>? sessions,
    List<Message>? messages,
    String? currentStreamingText,
    String? error,
    List<String>? models,
    String? selectedModel,
  }) {
    return ChatState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessions: sessions ?? this.sessions,
      messages: messages ?? this.messages,
      currentStreamingText: currentStreamingText,
      error: error,
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    isLoading,
    isStreaming,
    currentSessionId,
    sessions,
    messages,
    currentStreamingText,
    error,
    models,
    selectedModel,
  ];
}
