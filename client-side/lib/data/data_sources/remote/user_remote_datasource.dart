import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/user_mapper.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/user.pbgrpc.dart' as userpb;

abstract class IUserRemoteDataSource {
  Future<List<User>> getUsers({required int page, required int pageSize});

  Future<User> createUser({
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  });

  Future<User> editUser({
    required String id,
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  });
}

class UserRemoteDataSource implements IUserRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  UserRemoteDataSource(this._channelManager, this._authGuard);

  userpb.UserServiceClient get _client => _channelManager.userClient;

  @override
  Future<List<User>> getUsers({required int page, required int pageSize}) async {
    Logs().d('UserRemoteDataSource: получение пользователей page=$page');
    try {
      final req = userpb.GetUsersRequest(
        page: page,
        pageSize: pageSize,
      );
      final resp = await _authGuard.execute(() => _client.getUsers(req));
      final users = UserMapper.listFromProto(resp.users);
      Logs().i('UserRemoteDataSource: получено пользователей: ${users.length}');
      return users;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.permissionDenied) {
        Logs().w('UserRemoteDataSource: доступ запрещён');
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      Logs().e('UserRemoteDataSource: ошибка получения пользователей', e);
      throwGrpcError(e, 'Ошибка получения пользователей');
    } catch (e) {
      Logs().e('UserRemoteDataSource: ошибка получения пользователей', e);
      throw ApiFailure('Ошибка получения пользователей');
    }
  }

  @override
  Future<User> createUser({
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  }) async {
    Logs().d('UserRemoteDataSource: создание пользователя $username');
    try {
      final req = userpb.CreateUserRequest(
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
      final resp = await _authGuard.execute(() => _client.createUser(req));
      Logs().i('UserRemoteDataSource: пользователь создан');
      return UserMapper.fromProto(resp.user);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.invalidArgument) {
        Logs().w('UserRemoteDataSource: неверные данные при создании');
        throw NetworkFailure('Неверные данные');
      }

      if (e.code == StatusCode.permissionDenied) {
        Logs().w('UserRemoteDataSource: доступ запрещён');
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      Logs().e('UserRemoteDataSource: ошибка создания пользователя', e);
      throwGrpcError(e, 'Ошибка создания пользователя');
    } catch (e) {
      Logs().e('UserRemoteDataSource: ошибка создания пользователя', e);
      throw ApiFailure('Ошибка создания пользователя');
    }
  }

  @override
  Future<User> editUser({
    required String id,
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  }) async {
    Logs().d('UserRemoteDataSource: обновление пользователя $id');
    try {
      final req = userpb.EditUserRequest(
        id: id,
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
      final resp = await _authGuard.execute(() => _client.editUser(req));
      Logs().i('UserRemoteDataSource: пользователь обновлён');
      return UserMapper.fromProto(resp.user);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.invalidArgument) {
        Logs().w('UserRemoteDataSource: неверные данные при обновлении');
        throw NetworkFailure('Неверные данные');
      }

      if (e.code == StatusCode.permissionDenied) {
        Logs().w('UserRemoteDataSource: доступ запрещён');
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      Logs().e('UserRemoteDataSource: ошибка обновления пользователя', e);
      throwGrpcError(e, 'Ошибка обновления пользователя');
    } catch (e) {
      Logs().e('UserRemoteDataSource: ошибка обновления пользователя', e);
      throw ApiFailure('Ошибка обновления пользователя');
    }
  }
}
