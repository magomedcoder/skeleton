import 'package:legion/domain/repositories/project_repository.dart';

class DeleteProjectColumnUseCase {
  final ProjectRepository repo;

  DeleteProjectColumnUseCase(this.repo);

  Future<void> call(String id) => repo.deleteProjectColumn(id);
}
