import 'package:legion/domain/repositories/project_repository.dart';

class AddUserToProjectUseCase {
  final ProjectRepository repo;

  AddUserToProjectUseCase(this.repo);

  Future<void> call(String projectId, List<int> userIds) => repo.addUserToProject(projectId, userIds);
}
