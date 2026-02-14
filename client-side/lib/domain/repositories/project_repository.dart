import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/task_comment.dart';
import 'package:legion/domain/entities/user.dart';

abstract class ProjectRepository {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(String id);

  Future<void> addUserToProject(String projectId, List<int> userIds);

  Future<List<User>> getProjectMembers(String projectId);

  Future<Task> createTask(String projectId, String name, String description, int executor);

  Future<List<Task>> getTasks(String projectId);

  Future<Task> getTask(String taskId);

  Future<void> editTaskColumnId(String taskId, String columnId);

  Future<Task> editTask(String taskId, String name, String description, int assigner, int executor);

  Future<List<BoardColumn>> getProjectColumns(String projectId);

  Future<BoardColumn> createProjectColumn(String projectId, String title, String color, {String? statusKey});

  Future<void> editProjectColumn(String id, {String? title, String? color, String? statusKey, int? position});

  Future<void> deleteProjectColumn(String id);

  Future<List<TaskComment>> getTaskComments(String taskId);

  Future<void> addTaskComment(String taskId, String body);
}
