import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetProjectColumnsUseCase {
  final ProjectRepository repo;

  GetProjectColumnsUseCase(this.repo);

  Future<List<BoardColumn>> call(String projectId) => repo.getProjectColumns(projectId);
}
