import 'package:skeleton/data/data_sources/local/user_local_data_source.dart';
import 'package:skeleton/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;
  final UserLocalDataSource tokenStorage;

  ChangePasswordUseCase(this.repository, this.tokenStorage);

  Future<void> call(String oldPassword, String newPassword) async {
    final currentRefreshToken = tokenStorage.refreshToken;
    return await repository.changePassword(oldPassword, newPassword, currentRefreshToken);
  }
}
