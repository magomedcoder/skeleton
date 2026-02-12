import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/user.dart';

abstract class ProjectRepository {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(String id);

  Future<void> addUserToProject(String projectId, List<int> userIds);

  Future<List<User>> getProjectMembers(String projectId);
}
