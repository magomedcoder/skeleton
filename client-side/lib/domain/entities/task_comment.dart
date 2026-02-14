import 'package:equatable/equatable.dart';

class TaskComment extends Equatable {
  final String id;
  final String taskId;
  final int userId;
  final String body;
  final int createdAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.body,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, taskId, userId, body, createdAt];
}
