import 'package:grpc/grpc.dart';
import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/grpc_channel_manager.dart';
import 'package:skeleton/core/grpc_error_handler.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/data/mappers/auth_mapper.dart';
import 'package:skeleton/domain/entities/auth_result.dart';
import 'package:skeleton/domain/entities/auth_tokens.dart';
import 'package:skeleton/domain/entities/device.dart';
import 'package:skeleton/data/data_sources/local/user_local_data_source.dart';
import 'package:skeleton/generated/grpc_pb/auth.pbgrpc.dart' as grpc;

abstract class IAuthRemoteDataSource {
  Future<AuthResult> login(String username, String password);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final UserLocalDataSourceImpl _tokenStorage;

  AuthRemoteDataSource(this._channelManager, this._tokenStorage);

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
  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]) async {
    Logs().d('AuthRemoteDataSource: смена пароля');
    try {
      final request = grpc.ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      final refreshToken = currentRefreshToken ?? _tokenStorage.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        request.currentRefreshToken = refreshToken.trim();
      }

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

  @override
  Future<List<Device>> getDevices() async {
    Logs().d('AuthRemoteDataSource: список устройств');
    try {
      final request = grpc.GetDevicesRequest();
      final response = await _client.getDevices(request);
      final devices = response.devices
        .map((d) => Device(
          id: d.id,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            d.createdAtSeconds.toInt() * 1000,
          ),
        ))
        .toList();
      Logs().i('AuthRemoteDataSource: получено ${devices.length} устройств');
      return devices;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка списка устройств', e);
      throwGrpcError(e, 'Ошибка загрузки устройств');
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    Logs().d('AuthRemoteDataSource: отзыв устройства $deviceId');
    try {
      final request = grpc.RevokeDeviceRequest(deviceId: deviceId);
      await _client.revokeDevice(request);
      Logs().i('AuthRemoteDataSource: устройство отозвано');
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка отзыва устройства', e);
      if (e.code == StatusCode.notFound) {
        throw NetworkFailure('Устройство не найдено');
      }
      throwGrpcError(e, 'Ошибка отзыва устройства');
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }
}
