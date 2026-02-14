import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class CreateProjectColumnUseCase {
  final ProjectRepository repo;

  CreateProjectColumnUseCase(this.repo);

  Future<BoardColumn> call(
    String projectId,
    String title,
    String color, {
    String? statusKey,
  }) => repo.createProjectColumn(projectId, title, color, statusKey: statusKey);
}
