import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/data/mappers/user_mapper.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/user.pbgrpc.dart' as grpc;

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
  final grpc.UserServiceClient _client;

  UserRemoteDataSource(this._client);

  @override
  Future<List<User>> getUsers({required int page, required int pageSize}) async {
    try {
      final req = grpc.GetUsersRequest(
        page: page,
        pageSize: pageSize,
      );
      final resp = await _client.getUsers(req);
      return UserMapper.listFromProto(resp.users);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.permissionDenied) {
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      
      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Сессия истекла, войдите снова');
      }

      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка получения пользователей: $e');
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
    try {
      final req = grpc.CreateUserRequest(
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
      final resp = await _client.createUser(req);
      return UserMapper.fromProto(resp.user);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure(e.message ?? 'Неверные данные');
      }

      if (e.code == StatusCode.permissionDenied) {
        throw NetworkFailure('Доступ разрешён только администратору');
      }

      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Сессия истекла, войдите снова');
      }

      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка создания пользователя: $e');
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
    try {
      final req = grpc.EditUserRequest(
        id: id,
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
      final resp = await _client.editUser(req);
      return UserMapper.fromProto(resp.user);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure(e.message ?? 'Неверные данные');
      }

      if (e.code == StatusCode.permissionDenied) {
        throw NetworkFailure('Доступ разрешён только администратору');
      }

      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Сессия истекла, войдите снова');
      }

      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка обновления пользователя: $e');
    }
  }
}
