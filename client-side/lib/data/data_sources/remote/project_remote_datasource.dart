import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/project_mapper.dart';
import 'package:legion/data/mappers/task_mapper.dart';
import 'package:legion/data/mappers/user_mapper.dart';
import 'package:legion/data/mappers/board_column_mapper.dart';
import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/task_comment.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/project.pbgrpc.dart' as projectpb;

abstract class IProjectRemoteDataSource {
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

class ProjectRemoteDataSource implements IProjectRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ProjectRemoteDataSource(this._channelManager, this._authGuard);

  projectpb.ProjectServiceClient get _client => _channelManager.projectClient;

  @override
  Future<Project> createProject(String name) async {
    Logs().d('ProjectRemoteDataSource: createProject name=$name');
    try {
      final req = projectpb.CreateProjectRequest(name: name);
      final resp = await _authGuard.execute(() => _client.createProject(req));

      return Project(id: resp.id, name: name);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createProject', e);
      throwGrpcError(e, 'Ошибка создания проекта');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createProject', e);
      throw ApiFailure('Ошибка создания проекта');
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    Logs().d('ProjectRemoteDataSource: getProjects');
    try {
      final req = projectpb.GetProjectsRequest();
      final resp = await _authGuard.execute(() => _client.getProjects(req));

      return ProjectMapper.listFromProto(resp.items);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjects', e);
      throwGrpcError(e, 'Ошибка получения проектов');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjects', e);
      throw ApiFailure('Ошибка получения проектов');
    }
  }

  @override
  Future<Project> getProject(String id) async {
    Logs().d('ProjectRemoteDataSource: getProject id=$id');
    try {
      final req = projectpb.GetProjectRequest(id: id);
      final resp = await _authGuard.execute(() => _client.getProject(req));

      return Project(id: resp.id, name: resp.name);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProject', e);
      throwGrpcError(e, 'Ошибка получения проекта');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProject', e);
      throw ApiFailure('Ошибка получения проекта');
    }
  }

  @override
  Future<void> addUserToProject(String projectId, List<int> userIds) async {
    Logs().d('ProjectRemoteDataSource: addUserToProject projectId=$projectId');
    try {
      final req = projectpb.AddUserToProjectRequest(
        projectId: projectId,
        userIds: userIds.map((id) => Int64(id)).toList(),
      );
      await _authGuard.execute(() => _client.addUserToProject(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в addUserToProject', e);
      throwGrpcError(e, 'Ошибка добавления участников');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в addUserToProject', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<List<User>> getProjectMembers(String projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectMembers projectId=$projectId');
    try {
      final req = projectpb.GetProjectMembersRequest(projectId: projectId);
      final resp = await _authGuard.execute(
        () => _client.getProjectMembers(req),
      );

      return UserMapper.listFromProto(resp.items);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectMembers', e);
      throwGrpcError(e, 'Ошибка получения участников');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectMembers', e);
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
    Logs().d(
      'ProjectRemoteDataSource: createTask projectId=$projectId, name=$name, executor=$executor',
    );
    try {
      final req = projectpb.CreateTaskRequest(
        projectId: projectId,
        name: name,
        description: description,
        executor: Int64(executor),
      );
      final resp = await _authGuard.execute(() => _client.createTask(req));

      final taskReq = projectpb.GetTaskRequest(taskId: resp.id);
      final taskResp = await _authGuard.execute(() => _client.getTask(taskReq));

      return Task(
        id: taskResp.id,
        projectId: projectId,
        name: taskResp.name,
        description: taskResp.description,
        createdAt: taskResp.createdAt.toInt(),
        assigner: taskResp.assigner.toInt(),
        executor: taskResp.executor.toInt(),
        columnId: taskResp.columnId.isNotEmpty ? taskResp.columnId : '',
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createTask', e);
      throwGrpcError(e, 'Ошибка создания задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createTask', e);
      throw ApiFailure('Ошибка создания задачи');
    }
  }

  @override
  Future<List<Task>> getTasks(String projectId) async {
    Logs().d('ProjectRemoteDataSource: getTasks projectId=$projectId');
    try {
      final req = projectpb.GetTasksRequest(projectId: projectId);
      final resp = await _authGuard.execute(() => _client.getTasks(req));

      return TaskMapper.listFromProto(resp.tasks, projectId: projectId);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTasks', e);
      throwGrpcError(e, 'Ошибка получения задач');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTasks', e);
      throw ApiFailure('Ошибка получения задач');
    }
  }

  @override
  Future<Task> getTask(String taskId) async {
    Logs().d('ProjectRemoteDataSource: getTask taskId=$taskId');
    try {
      final req = projectpb.GetTaskRequest(taskId: taskId);
      final resp = await _authGuard.execute(() => _client.getTask(req));

      return Task(
        id: resp.id,
        projectId: '',
        name: resp.name,
        description: resp.description,
        createdAt: resp.createdAt.toInt(),
        assigner: resp.assigner.toInt(),
        executor: resp.executor.toInt(),
        columnId: resp.columnId.isNotEmpty ? resp.columnId : '',
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTask', e);
      throwGrpcError(e, 'Ошибка получения задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTask', e);
      throw ApiFailure('Ошибка получения задачи');
    }
  }

  @override
  Future<void> editTaskColumnId(String taskId, String columnId) async {
    Logs().d('ProjectRemoteDataSource: editTaskColumnId taskId=$taskId, columnId=$columnId');
    try {
      final req = projectpb.EditTaskColumnIdRequest(
        taskId: taskId,
        columnId: columnId,
      );
      await _authGuard.execute(() => _client.editTaskColumnId(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editTaskColumnId', e);
      throwGrpcError(e, 'Ошибка обновления колонки задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editTaskColumnId', e);
      throw ApiFailure('Ошибка обновления колонки задачи');
    }
  }

  @override
  Future<Task> editTask(String taskId, String name, String description, int assigner, int executor) async {
    Logs().d('ProjectRemoteDataSource: editTask taskId=$taskId');
    try {
      final req = projectpb.EditTaskRequest(
        taskId: taskId,
        name: name,
        description: description,
        assigner: Int64(assigner),
        executor: Int64(executor),
      );
      await _authGuard.execute(() => _client.editTask(req));
      final taskReq = projectpb.GetTaskRequest(taskId: taskId);
      final taskResp = await _authGuard.execute(() => _client.getTask(taskReq));
      return Task(
        id: taskResp.id,
        projectId: '',
        name: taskResp.name,
        description: taskResp.description,
        createdAt: taskResp.createdAt.toInt(),
        assigner: taskResp.assigner.toInt(),
        executor: taskResp.executor.toInt(),
        columnId: taskResp.columnId.isNotEmpty ? taskResp.columnId : '',
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editTask', e);
      throwGrpcError(e, 'Ошибка обновления задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editTask', e);
      throw ApiFailure('Ошибка обновления задачи');
    }
  }

  @override
  Future<List<BoardColumn>> getProjectColumns(String projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectColumns projectId=$projectId');
    try {
      final req = projectpb.GetProjectColumnsRequest(projectId: projectId);
      final resp = await _authGuard.execute(() => _client.getProjectColumns(req));
      return BoardColumnMapper.listFromProto(resp.columns);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectColumns', e);
      throwGrpcError(e, 'Ошибка загрузки колонок');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectColumns', e);
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
    Logs().d('ProjectRemoteDataSource: createProjectColumn projectId=$projectId, title=$title');
    try {
      final req = projectpb.CreateProjectColumnRequest(
        projectId: projectId,
        title: title,
        color: color,
        statusKey: statusKey ?? '',
      );
      final resp = await _authGuard.execute(() => _client.createProjectColumn(req));
      final list = await getProjectColumns(projectId);
      try {
        return list.firstWhere((c) => c.id == resp.id);
      } catch (_) {}
      return BoardColumn(
        id: resp.id,
        projectId: projectId,
        title: title,
        color: color,
        statusKey: statusKey ?? _slugFromTitle(title),
        position: list.length,
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createProjectColumn', e);
      throwGrpcError(e, 'Ошибка создания колонки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createProjectColumn', e);
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
    Logs().d('ProjectRemoteDataSource: editProjectColumn id=$id');
    try {
      final req = projectpb.EditProjectColumnRequest(
        id: id,
        title: title ?? '',
        color: color ?? '',
        statusKey: statusKey ?? '',
        position: position ?? -1,
      );
      await _authGuard.execute(() => _client.editProjectColumn(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editProjectColumn', e);
      throwGrpcError(e, 'Ошибка обновления колонки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editProjectColumn', e);
      throw ApiFailure('Ошибка обновления колонки');
    }
  }

  @override
  Future<void> deleteProjectColumn(String id) async {
    Logs().d('ProjectRemoteDataSource: deleteProjectColumn id=$id');
    try {
      final req = projectpb.DeleteProjectColumnRequest(id: id);
      await _authGuard.execute(() => _client.deleteProjectColumn(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в deleteProjectColumn', e);
      throwGrpcError(e, 'Ошибка удаления колонки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в deleteProjectColumn', e);
      throw ApiFailure('Ошибка удаления колонки');
    }
  }

  @override
  Future<List<TaskComment>> getTaskComments(String taskId) async {
    Logs().d('ProjectRemoteDataSource: getTaskComments taskId=$taskId');
    try {
      final req = projectpb.GetTaskCommentsRequest(taskId: taskId);
      final resp = await _authGuard.execute(() => _client.getTaskComments(req));
      return resp.comments.map((c) => TaskComment(
        id: c.id,
        taskId: c.taskId,
        userId: c.userId.toInt(),
        body: c.body,
        createdAt: c.createdAt.toInt(),
      ))
      .toList();
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTaskComments', e);
      throwGrpcError(e, 'Ошибка загрузки комментариев');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTaskComments', e);
      throw ApiFailure('Ошибка загрузки комментариев');
    }
  }

  @override
  Future<void> addTaskComment(String taskId, String body) async {
    Logs().d('ProjectRemoteDataSource: addTaskComment taskId=$taskId');
    try {
      final req = projectpb.AddTaskCommentRequest(taskId: taskId, body: body);
      await _authGuard.execute(() => _client.addTaskComment(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в addTaskComment', e);
      throwGrpcError(e, 'Ошибка добавления комментария');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в addTaskComment', e);
      throw ApiFailure('Ошибка добавления комментария');
    }
  }

  static String _slugFromTitle(String title) {
    final sb = StringBuffer();
    for (var i = 0; i < title.length; i++) {
      final r = title.codeUnitAt(i);
      if (r >= 0x61 && r <= 0x7a || r >= 0x30 && r <= 0x39) {
        sb.writeCharCode(r);
      } else if (r >= 0x41 && r <= 0x5a) {
        sb.writeCharCode(r + 32);
      } else if (r == 0x20 || r == 0x2d || r == 0x5f) {
        if (sb.length > 0 && sb.toString().codeUnitAt(sb.length - 1) != 0x5f) {
          sb.writeCharCode(0x5f);
        }
      }
    }
    var s = sb.toString();
    if (s.isEmpty) return 'column';
    if (s.codeUnitAt(s.length - 1) == 0x5f) s = s.substring(0, s.length - 1);
    return s;
  }
}
