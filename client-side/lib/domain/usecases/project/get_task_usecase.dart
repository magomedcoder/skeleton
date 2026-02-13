import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetTaskUseCase {
  final ProjectRepository repo;

  GetTaskUseCase(this.repo);

  Future<Task> call(String taskId) => repo.getTask(taskId);
}
