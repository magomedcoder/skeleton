import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class Message extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
  };

  @override
  List<Object?> get props => [id, content, role, createdAt];
}
