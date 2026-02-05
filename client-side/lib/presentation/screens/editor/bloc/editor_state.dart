import 'package:equatable/equatable.dart';
import 'package:skeleton/generated/grpc_pb/editor.pb.dart' as grpc;

class EditorState extends Equatable {
  final bool isLoading;
  final String inputText;
  final String outputText;
  final List<String> models;
  final String? selectedModel;
  final String? error;

  const EditorState({
    this.isLoading = false,
    this.inputText = '',
    this.outputText = '',
    this.models = const [],
    this.selectedModel,
    this.error,
  });

  EditorState copyWith({
    bool? isLoading,
    String? inputText,
    String? outputText,
    List<String>? models,
    String? selectedModel,
    bool clearSelectedModel = false,
    String? error,
    bool clearError = false,
  }) {
    return EditorState(
      isLoading: isLoading ?? this.isLoading,
      inputText: inputText ?? this.inputText,
      outputText: outputText ?? this.outputText,
      models: models ?? this.models,
      selectedModel: clearSelectedModel ? null : (selectedModel ?? this.selectedModel),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    inputText,
    outputText,
    models,
    selectedModel,
    error,
  ];
}
