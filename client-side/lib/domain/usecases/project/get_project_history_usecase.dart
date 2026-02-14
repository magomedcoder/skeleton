import 'package:legion/domain/entities/project_activity.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetProjectHistoryUseCase {
  final ProjectRepository repo;

  GetProjectHistoryUseCase(this.repo);

  Future<List<ProjectActivity>> call(String projectId) => repo.getProjectHistory(projectId);
}
