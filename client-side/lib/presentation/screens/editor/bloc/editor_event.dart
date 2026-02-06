import 'package:equatable/equatable.dart';
import 'package:skeleton/generated/grpc_pb/editor.pb.dart' as grpc;

sealed class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object?> get props => [];
}

final class EditorStarted extends EditorEvent {
  const EditorStarted();
}

final class EditorInputChanged extends EditorEvent {
  final String text;

  const EditorInputChanged(this.text);

  @override
  List<Object?> get props => [text];
}

final class EditorTypeChanged extends EditorEvent {
  final grpc.TransformType type;
  const EditorTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

final class EditorModelChanged extends EditorEvent {
  final String? model;

  const EditorModelChanged(this.model);

  @override
  List<Object?> get props => [model];
}

final class EditorPreserveMarkdownChanged extends EditorEvent {
  final bool preserve;

  const EditorPreserveMarkdownChanged(this.preserve);

  @override
  List<Object?> get props => [preserve];
}

final class EditorTransformPressed extends EditorEvent {
  const EditorTransformPressed();
}

final class EditorClearError extends EditorEvent {
  const EditorClearError();
}
