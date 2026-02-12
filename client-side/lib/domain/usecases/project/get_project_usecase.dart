import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetProjectUseCase {
  final ProjectRepository repo;

  GetProjectUseCase(this.repo);

  Future<Project> call(String id) => repo.getProject(id);
}
