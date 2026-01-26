import 'package:legion/domain/entities/auth_tokens.dart';
import 'package:legion/domain/repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<AuthTokens> call(String refreshToken) async {
    return await repository.refreshToken(refreshToken);
  }
}
