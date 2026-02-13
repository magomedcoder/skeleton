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
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/project.pbgrpc.dart' as projectpb;

abstract class IProjectRemoteDataSource {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(String id);

  Future<void> addUserToProject(String projectId, List<int> userIds);

  Future<List<User>> getProjectMembers(String projectId);

  Future<Task> createTask(String projectId, String name, String description);

  Future<List<Task>> getTasks(String projectId);

  Future<Task> getTask(String taskId);
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
  ) async {
    Logs().d(
      'ProjectRemoteDataSource: createTask projectId=$projectId, name=$name',
    );
    try {
      final req = projectpb.CreateTaskRequest(
        projectId: projectId,
        name: name,
        description: description,
      );
      final resp = await _authGuard.execute(() => _client.createTask(req));

      return Task(
        id: resp.id,
        projectId: projectId,
        name: name,
        description: description,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTask', e);
      throwGrpcError(e, 'Ошибка получения задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTask', e);
      throw ApiFailure('Ошибка получения задачи');
    }
  }
}
