import 'package:legion/domain/entities/auth_result.dart';
import 'package:legion/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResult> call(String email, String password) async {
    return await repository.login(email, password);
  }
}
