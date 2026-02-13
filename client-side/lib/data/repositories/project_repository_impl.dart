import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/project_remote_datasource.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final IProjectRemoteDataSource _remote;

  ProjectRepositoryImpl(this._remote);

  @override
  Future<Project> createProject(String name) async {
    try {
      return await _remote.createProject(name);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createProject', e);
      throw ApiFailure('Ошибка создания проекта');
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    try {
      return await _remote.getProjects();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjects', e);
      throw ApiFailure('Ошибка получения проектов');
    }
  }

  @override
  Future<Project> getProject(String id) async {
    try {
      return await _remote.getProject(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProject', e);
      throw ApiFailure('Ошибка получения проекта');
    }
  }

  @override
  Future<void> addUserToProject(String projectId, List<int> userIds) async {
    try {
      return await _remote.addUserToProject(projectId, userIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в addUserToProject', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<List<User>> getProjectMembers(String projectId) async {
    try {
      return await _remote.getProjectMembers(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectMembers', e);
      throw ApiFailure('Ошибка получения участников');
    }
  }

  @override
  Future<Task> createTask(
    String projectId,
    String name,
    String description,
  ) async {
    try {
      return await _remote.createTask(projectId, name, description);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createTask', e);
      throw ApiFailure('Ошибка создания задачи');
    }
  }

  @override
  Future<List<Task>> getTasks(String projectId) async {
    try {
      return await _remote.getTasks(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTasks', e);
      throw ApiFailure('Ошибка получения задач');
    }
  }

  @override
  Future<Task> getTask(String taskId) async {
    try {
      return await _remote.getTask(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTask', e);
      throw ApiFailure('Ошибка получения задачи');
    }
  }
}
