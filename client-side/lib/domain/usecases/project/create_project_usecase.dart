import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class CreateProjectUseCase {
  final ProjectRepository repo;

  CreateProjectUseCase(this.repo);

  Future<Project> call(String name) => repo.createProject(name);
}
