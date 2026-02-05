import 'package:skeleton/domain/entities/auth_result.dart';
import 'package:skeleton/domain/entities/auth_tokens.dart';

abstract interface class AuthRepository {
  Future<AuthResult> login(String username, String password);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<void> changePassword(String oldPassword, String newPassword);
}
