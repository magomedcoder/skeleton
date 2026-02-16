import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/account_remote_datasource.dart';
import 'package:legion/data/mappers/account_update_mapper.dart';
import 'package:legion/domain/entities/account_update.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final IAccountRemoteDataSource dataSource;

  AccountRepositoryImpl(this.dataSource);

  @override
  Future<Stream<AccountUpdate>> getUpdates() async {
    Logs().i('AccountRepositoryImpl - getUpdates');

    return dataSource.getUpdates().asyncExpand((response) async* {
      Logs().i('ChatRepositoryImpl - getUpdates ${response.updates}');

      for (final update in response.updates) {
        final domainUpdate = AccountUpdateMapper.fromGrpc(update);
        if (domainUpdate != null) {
          yield domainUpdate;
        }
      }
    });
  }

  @override
  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    [String? currentRefreshToken]
  ) async {
    try {
      await dataSource.changePassword(oldPassword, newPassword, currentRefreshToken);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    try {
      return await dataSource.getDevices();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    try {
      await dataSource.revokeDevice(deviceId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }
}
