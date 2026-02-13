import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/task.dart';

class TaskState extends Equatable {
  final bool isLoading;
  final List<Task> tasks;
  final Task? selectedTask;
  final String? error;
  final String? projectId;

  const TaskState({
    this.isLoading = false,
    this.tasks = const [],
    this.selectedTask,
    this.error,
    this.projectId,
  });

  TaskState copyWith({
    bool? isLoading,
    List<Task>? tasks,
    Task? selectedTask,
    bool clearSelectedTask = false,
    String? error,
    String? projectId,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      selectedTask: clearSelectedTask
        ? null
        : (selectedTask ?? this.selectedTask),
      error: error,
      projectId: projectId ?? this.projectId,
    );
  }

  @override
  List<Object?> get props => [isLoading, tasks, selectedTask, error, projectId];
}
