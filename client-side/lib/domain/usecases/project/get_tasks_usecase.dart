import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetTasksUseCase {
  final ProjectRepository repo;

  GetTasksUseCase(this.repo);

  Future<List<Task>> call(String projectId) => repo.getTasks(projectId);
}
