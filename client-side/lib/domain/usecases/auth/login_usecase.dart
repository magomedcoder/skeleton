import 'package:skeleton/domain/entities/auth_result.dart';
import 'package:skeleton/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResult> call(String username, String password) async {
    return await repository.login(username, password);
  }
}
