import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:legion/domain/entities/auth_result.dart';
import 'package:legion/domain/entities/auth_tokens.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final IAuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<AuthResult> login(String username, String password) async {
    try {
      return await dataSource.login(username, password);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка входа', e);
      throw ApiFailure('Ошибка входа');
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      return await dataSource.refreshToken(refreshToken);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка обновления токена', e);
      throw ApiFailure('Ошибка обновления токена');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dataSource.logout();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка выхода', e);
      throw ApiFailure('Ошибка выхода');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]) async {
    try {
      await dataSource.changePassword(oldPassword, newPassword, currentRefreshToken);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    try {
      return await dataSource.getDevices();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    try {
      await dataSource.revokeDevice(deviceId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }
}
