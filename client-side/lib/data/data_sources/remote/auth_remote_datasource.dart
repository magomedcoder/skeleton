import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
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
    Logs().d('AuthRemoteDataSource: вход для пользователя $username');
    try {
      final request = grpc.LoginRequest(
        username: username,
        password: password,
      );

      final response = await _client.login(request);
      final result = AuthMapper.loginResponseFromProto(response);
      Logs().i('AuthRemoteDataSource: вход выполнен успешно');
      return result;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка входа (gRPC)', e);
      throwGrpcError(e, 'Ошибка входа',
        unauthenticatedMessage: 'Неверное имя пользователя или пароль',
      );
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка входа', e);
      throw ApiFailure('Ошибка входа');
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    Logs().d('AuthRemoteDataSource: обновление токена');
    try {
      final request = grpc.RefreshTokenRequest(
        refreshToken: refreshToken
      );

      final response = await _client.refreshToken(request);
      final tokens = AuthMapper.refreshTokenResponseFromProto(response);
      Logs().i('AuthRemoteDataSource: токен обновлён');
      return tokens;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка обновления токена', e);
      throwGrpcError(e, 'Ошибка обновления токена',
        unauthenticatedMessage: 'Недействительный refresh token',
      );
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка обновления токена', e);
      throw ApiFailure('Ошибка обновления токена');
    }
  }

  @override
  Future<void> logout() async {
    Logs().d('AuthRemoteDataSource: выход');
    try {
      final request = grpc.LogoutRequest();

      await _client.logout(request);
      Logs().i('AuthRemoteDataSource: выход выполнен');
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка выхода', e);
      throwGrpcError(e, 'Ошибка выхода');
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка выхода', e);
      throw ApiFailure('Ошибка выхода');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    Logs().d('AuthRemoteDataSource: смена пароля');
    try {
      final request = grpc.ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword
      );

      await _client.changePassword(request);
      Logs().i('AuthRemoteDataSource: пароль изменён');
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка смены пароля', e);
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure('Неверные данные');
      }

      throwGrpcError(e, 'Ошибка смены пароля');
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }
}
