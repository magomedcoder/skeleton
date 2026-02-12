import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository repo;

  GetProjectsUseCase(this.repo);

  Future<List<Project>> call() => repo.getProjects();
}
