import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum AIMessageRole { user, assistant }

class AIMessage extends Equatable {
  final String id;
  final String content;
  final AIMessageRole role;
  final DateTime createdAt;
  final String? attachmentFileName;
  final Uint8List? attachmentContent;

  const AIMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.attachmentFileName,
    this.attachmentContent,
  });

  @override
  List<Object?> get props => [id, content, role, createdAt, attachmentFileName];
}
