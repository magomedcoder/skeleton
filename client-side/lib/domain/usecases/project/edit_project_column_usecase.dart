import 'package:legion/domain/repositories/project_repository.dart';

class EditProjectColumnUseCase {
  final ProjectRepository repo;

  EditProjectColumnUseCase(this.repo);

  Future<void> call(
    String id, {
    String? title,
    String? color,
    String? statusKey,
    int? position,
  }) => repo.editProjectColumn(
    id,
    title: title,
    color: color,
    statusKey: statusKey,
    position: position,
  );
}
