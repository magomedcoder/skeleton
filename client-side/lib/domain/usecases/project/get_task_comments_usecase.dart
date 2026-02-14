import 'package:legion/domain/entities/task_comment.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class GetTaskCommentsUseCase {
  final ProjectRepository repo;

  GetTaskCommentsUseCase(this.repo);

  Future<List<TaskComment>> call(String taskId) => repo.getTaskComments(taskId);
}
