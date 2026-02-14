import 'package:legion/domain/entities/project_activity.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetTaskHistoryUseCase {
  final ProjectRepository repo;

  GetTaskHistoryUseCase(this.repo);

  Future<List<ProjectActivity>> call(String taskId) => repo.getTaskHistory(taskId);
}
