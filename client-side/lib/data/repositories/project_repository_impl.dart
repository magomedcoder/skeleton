import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/project_remote_datasource.dart';
import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/project_activity.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/task_comment.dart';
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
    int executor,
  ) async {
    try {
      return await _remote.createTask(projectId, name, description, executor);
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

  @override
  Future<void> editTaskColumnId(String taskId, String columnId) async {
    try {
      return await _remote.editTaskColumnId(taskId, columnId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editTaskColumnId', e);
      throw ApiFailure('Ошибка обновления колонки задачи');
    }
  }

  @override
  Future<Task> editTask(String taskId, String name, String description, int assigner, int executor) async {
    try {
      return await _remote.editTask(taskId, name, description, assigner, executor);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editTask', e);
      throw ApiFailure('Ошибка обновления задачи');
    }
  }

  @override
  Future<List<BoardColumn>> getProjectColumns(String projectId) async {
    try {
      return await _remote.getProjectColumns(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectColumns', e);
      throw ApiFailure('Ошибка загрузки колонок');
    }
  }

  @override
  Future<BoardColumn> createProjectColumn(
    String projectId,
    String title,
    String color, {
    String? statusKey,
  }) async {
    try {
      return await _remote.createProjectColumn(projectId, title, color, statusKey: statusKey);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createProjectColumn', e);
      throw ApiFailure('Ошибка создания колонки');
    }
  }

  @override
  Future<void> editProjectColumn(
    String id, {
    String? title,
    String? color,
    String? statusKey,
    int? position,
  }) async {
    try {
      return await _remote.editProjectColumn(
        id,
        title: title,
        color: color,
        statusKey: statusKey,
        position: position,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editProjectColumn', e);
      throw ApiFailure('Ошибка обновления колонки');
    }
  }

  @override
  Future<void> deleteProjectColumn(String id) async {
    try {
      return await _remote.deleteProjectColumn(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в deleteProjectColumn', e);
      throw ApiFailure('Ошибка удаления колонки');
    }
  }

  @override
  Future<List<TaskComment>> getTaskComments(String taskId) async {
    try {
      return await _remote.getTaskComments(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTaskComments', e);
      throw ApiFailure('Ошибка загрузки комментариев');
    }
  }

  @override
  Future<void> addTaskComment(String taskId, String body) async {
    try {
      return await _remote.addTaskComment(taskId, body);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в addTaskComment', e);
      throw ApiFailure('Ошибка добавления комментария');
    }
  }

  @override
  Future<List<ProjectActivity>> getProjectHistory(String projectId) async {
    try {
      return await _remote.getProjectHistory(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectHistory', e);
      throw ApiFailure('Ошибка загрузки истории');
    }
  }

  @override
  Future<List<ProjectActivity>> getTaskHistory(String taskId) async {
    try {
      return await _remote.getTaskHistory(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTaskHistory', e);
      throw ApiFailure('Ошибка загрузки истории задачи');
    }
  }
}
