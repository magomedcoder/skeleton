import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/repositories/user_repository.dart';

class CreateUserUseCase {
  final UserRepository repo;
  CreateUserUseCase(this.repo);

  Future<User> call({
    required String username,
    required String password,
    required String name,
    required String surname,
    required int role,
  }) {
    return repo.createUser(
      username: username,
      password: password,
      name: name,
      surname: surname,
      role: role,
    );
  }
}
