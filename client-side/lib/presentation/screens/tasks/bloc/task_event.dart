import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  final String projectId;

  const TasksLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class TaskCreateRequested extends TaskEvent {
  final String projectId;
  final String name;
  final String description;
  final int executor;

  const TaskCreateRequested({
    required this.projectId,
    required this.name,
    required this.description,
    required this.executor,
  });

  @override
  List<Object?> get props => [projectId, name, description, executor];
}

class TaskSelected extends TaskEvent {
  final Task task;

  const TaskSelected(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskClearSelection extends TaskEvent {
  const TaskClearSelection();
}

class TaskClearError extends TaskEvent {
  const TaskClearError();
}

class TaskColumnIdEditRequested extends TaskEvent {
  final String taskId;
  final String columnId;

  const TaskColumnIdEditRequested({
    required this.taskId,
    required this.columnId,
  });

  @override
  List<Object?> get props => [taskId, columnId];
}

class TaskEditRequested extends TaskEvent {
  final String taskId;
  final String name;
  final String description;
  final int assigner;
  final int executor;

  const TaskEditRequested({
    required this.taskId,
    required this.name,
    required this.description,
    required this.assigner,
    required this.executor,
  });

  @override
  List<Object?> get props => [taskId, name, description, assigner, executor];
}
