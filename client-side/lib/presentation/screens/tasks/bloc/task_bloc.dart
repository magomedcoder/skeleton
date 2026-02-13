import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/usecases/project/create_task_usecase.dart';
import 'package:legion/domain/usecases/project/get_tasks_usecase.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_event.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;

  TaskBloc({required this.getTasksUseCase, required this.createTaskUseCase})
    : super(const TaskState()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskSelected>(_onSelected);
    on<TaskClearSelection>(_onClearSelection);
    on<TaskClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(
      state.copyWith(isLoading: true, error: null, projectId: event.projectId),
    );
    try {
      final tasks = await getTasksUseCase(event.projectId);
      emit(state.copyWith(isLoading: false, tasks: tasks));
    } catch (e) {
      Logs().e('TaskBloc: ошибка загрузки задач', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка загрузки задач'));
    }
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final task = await createTaskUseCase(
        event.projectId,
        name,
        event.description,
      );
      final tasks = [...state.tasks, task];
      emit(state.copyWith(isLoading: false, tasks: tasks));
      add(TasksLoadRequested(event.projectId));
    } catch (e) {
      Logs().e('TaskBloc: ошибка создания задачи', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка создания задачи'));
    }
  }

  void _onSelected(TaskSelected event, Emitter<TaskState> emit) {
    emit(state.copyWith(selectedTask: event.task));
  }

  void _onClearSelection(TaskClearSelection event, Emitter<TaskState> emit) {
    emit(state.copyWith(clearSelectedTask: true));
  }

  void _onClearError(TaskClearError event, Emitter<TaskState> emit) {
    emit(state.copyWith(error: null));
  }
}
