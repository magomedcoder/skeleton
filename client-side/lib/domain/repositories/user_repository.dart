import 'package:skeleton/domain/entities/user.dart';

abstract interface class UserRepository {
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
