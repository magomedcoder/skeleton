import 'package:legion/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<void> call(String oldPassword, String newPassword) async {
    return await repository.changePassword(oldPassword, newPassword);
  }
}
