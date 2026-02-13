import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class CreateTaskUseCase {
  final ProjectRepository repo;

  CreateTaskUseCase(this.repo);

  Future<Task> call(String projectId, String name, String description, int executor) => repo.createTask(projectId, name, description, executor);
}
