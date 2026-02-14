import 'package:legion/domain/repositories/project_repository.dart';

class EditTaskColumnIdUseCase {
  final ProjectRepository repo;

  EditTaskColumnIdUseCase(this.repo);

  Future<void> call(String taskId, String columnId) => repo.editTaskColumnId(taskId, columnId);
}
