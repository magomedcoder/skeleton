import 'package:equatable/equatable.dart';

class ProjectActivity extends Equatable {
  final String id;
  final String projectId;
  final String taskId;
  final int userId;
  final String action;
  final String payload;
  final int createdAt;

  const ProjectActivity({
    required this.id,
    required this.projectId,
    this.taskId = '',
    required this.userId,
    required this.action,
    this.payload = '',
    required this.createdAt,
  });

  String get actionLabel {
    switch (action) {
      case 'created_project':
        return 'Создан проект';
      case 'created_task':
        return 'Создана задача';
      case 'edited_task':
        return 'Задача изменена';
      case 'moved_task':
        return 'Задача перемещена';
      case 'comment_added':
        return 'Добавлен комментарий';
      case 'column_created':
        return 'Добавлена колонка';
      case 'column_edited':
        return 'Колонка изменена';
      case 'column_deleted':
        return 'Колонка удалена';
      case 'member_added':
        return 'Добавлен участник';
      default:
        return action;
    }
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    taskId,
    userId,
    action,
    payload,
    createdAt,
  ];
}
