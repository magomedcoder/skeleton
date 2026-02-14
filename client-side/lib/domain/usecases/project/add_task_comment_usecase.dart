import 'package:legion/domain/repositories/project_repository.dart';

class AddTaskCommentUseCase {
  final ProjectRepository repo;

  AddTaskCommentUseCase(this.repo);

  Future<void> call(String taskId, String body) => repo.addTaskComment(taskId, body);
}
