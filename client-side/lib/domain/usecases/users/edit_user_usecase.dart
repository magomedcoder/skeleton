import 'package:skeleton/domain/entities/user.dart';
import 'package:skeleton/domain/repositories/user_repository.dart';

class EditUserUseCase {
  final UserRepository repo;
  EditUserUseCase(this.repo);

  Future<User> call({
    required String id,
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  }) {
    return repo.editUser(
      id: id,
      username: username,
      password: password,
      name: name,
      surname: surname,
      role: role,
    );
  }
}
