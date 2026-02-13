import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/task.dart';
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
}
