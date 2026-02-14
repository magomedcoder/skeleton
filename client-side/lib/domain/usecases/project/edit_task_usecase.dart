import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class EditTaskUseCase {
  final ProjectRepository repo;

  EditTaskUseCase(this.repo);

  Future<Task> call(
    String taskId,
    String name,
    String description,
    int assigner,
    int executor,
  ) => repo.editTask(taskId, name, description, assigner, executor);
}
