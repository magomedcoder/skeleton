import 'package:legion/core/failures.dart';
import 'package:legion/data/data_sources/remote/user_remote_datasource.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final IUserRemoteDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<User>> getUsers({required int page, required int pageSize}) async {
    try {
      return await dataSource.getUsers(page: page, pageSize: pageSize);
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
      return await dataSource.createUser(
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
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
      return await dataSource.editUser(
        id: id,
        username: username,
        password: password,
        name: name,
        surname: surname,
        role: role,
      );
    } catch (e) {
      throw ApiFailure('Ошибка обновления пользователя: $e');
    }
  }
}
