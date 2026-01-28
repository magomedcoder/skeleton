import 'package:legion/core/failures.dart';
import 'package:legion/domain/entities/auth_result.dart';
import 'package:legion/domain/entities/auth_tokens.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/auth.pbgrpc.dart' as grpc;
import 'package:grpc/grpc.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthResult> login(String username, String password);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<void> changePassword(String oldPassword, String newPassword);
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final grpc.AuthServiceClient _client;

  AuthRemoteDataSource(this._client);

  @override
  Future<AuthResult> login(String username, String password) async {
    try {
      final request = grpc.LoginRequest(
        username: username,
        password: password,
      );

      final response = await _client.login(request);

      final user = User(
        id: response.user.id,
        username: response.user.username,
        name: response.user.name,
        surname: response.user.surname,
        role: response.user.role,
      );

      final tokens = AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return AuthResult(user: user, tokens: tokens);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Неверное имя пользователя или пароль');
      }
      
      throw NetworkFailure('Ошибка gRPC при входе: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка входа: $e');
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      final request = grpc.RefreshTokenRequest(
        refreshToken: refreshToken
      );

      final response = await _client.refreshToken(request);

      return AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Недействительный refresh token');
      }

      throw NetworkFailure('Ошибка gRPC при обновлении токена: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка обновления токена: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final request = grpc.LogoutRequest();

      await _client.logout(request);
    } on GrpcError catch (e) {
      throw NetworkFailure('Ошибка gRPC при выходе: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка выхода: $e');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final request = grpc.ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword
      );

      await _client.changePassword(request);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure(e.message ?? 'Неверные данные');
      }

      if (e.code == StatusCode.unauthenticated) {
        throw NetworkFailure('Сессия истекла, войдите снова');
      }
      throw NetworkFailure('Ошибка gRPC при смене пароля: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка смены пароля: $e');
    }
  }
}
