import 'package:skeleton/domain/entities/ai_message.dart';
import 'package:skeleton/domain/entities/ai_chat_session.dart';
import 'package:equatable/equatable.dart';

class AIChatState extends Equatable {
  final bool isConnected;
  final bool isLoading;
  final bool isStreaming;
  final String? currentSessionId;
  final List<AIChatSession> sessions;
  final List<AIMessage> messages;
  final String? currentStreamingText;
  final String? error;
  final List<String> models;
  final String? selectedModel;
  final bool? hasActiveRunners;

  const AIChatState({
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
    this.hasActiveRunners,
  });

  AIChatState copyWith({
    bool? isConnected,
    bool? isLoading,
    bool? isStreaming,
    String? currentSessionId,
    bool clearCurrentSessionId = false,
    List<AIChatSession>? sessions,
    List<AIMessage>? messages,
    String? currentStreamingText,
    String? error,
    List<String>? models,
    String? selectedModel,
    bool? hasActiveRunners,
  }) {
    return AIChatState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      currentSessionId: clearCurrentSessionId
        ? null
        : (currentSessionId ?? this.currentSessionId),
      sessions: sessions ?? this.sessions,
      messages: messages ?? this.messages,
      currentStreamingText: currentStreamingText,
      error: error,
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      hasActiveRunners: hasActiveRunners ?? this.hasActiveRunners,
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
    hasActiveRunners,
  ];
}
