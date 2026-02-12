import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetProjectMembersUseCase {
  final ProjectRepository repo;

  GetProjectMembersUseCase(this.repo);

  Future<List<User>> call(String projectId) => repo.getProjectMembers(projectId);
}
