import 'package:legion/domain/repositories/project_repository.dart';

class UpdateTaskColumnIdUseCase {
  final ProjectRepository repo;

  UpdateTaskColumnIdUseCase(this.repo);

  Future<void> call(String taskId, String columnId) => repo.updateTaskColumnId(taskId, columnId);
}
