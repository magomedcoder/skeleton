import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/data/mappers/auth_mapper.dart';
import 'package:legion/domain/entities/auth_result.dart';
import 'package:legion/domain/entities/auth_tokens.dart';
import 'package:legion/generated/grpc_pb/auth.pbgrpc.dart' as grpc;

abstract class IAuthRemoteDataSource {
  Future<AuthResult> login(String username, String password);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<void> changePassword(String oldPassword, String newPassword);
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final GrpcChannelManager _channelManager;

  AuthRemoteDataSource(this._channelManager);

  grpc.AuthServiceClient get _client => _channelManager.authClient;

  @override
  Future<AuthResult> login(String username, String password) async {
    try {
      final request = grpc.LoginRequest(
        username: username,
        password: password,
      );

      final response = await _client.login(request);

      return AuthMapper.loginResponseFromProto(response);
    } on GrpcError catch (e) {
      throwGrpcError(e, 'Ошибка gRPC при входе: ${e.message}',
        unauthenticatedMessage: 'Неверное имя пользователя или пароль',
      );
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

      return AuthMapper.refreshTokenResponseFromProto(response);
    } on GrpcError catch (e) {
      throwGrpcError(e, 'Ошибка gRPC при обновлении токена: ${e.message}',
        unauthenticatedMessage: 'Недействительный refresh token',
      );
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

      throwGrpcError(e, 'Ошибка gRPC при смене пароля: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка смены пароля: $e');
    }
  }
}
