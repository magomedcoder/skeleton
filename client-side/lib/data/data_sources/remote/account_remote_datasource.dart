import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/generated/grpc_pb/account.pbgrpc.dart' as accountpb;

abstract class IAccountRemoteDataSource {
  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);
}

class AccountRemoteDataSource implements IAccountRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final UserLocalDataSourceImpl _tokenStorage;

  AccountRemoteDataSource(this._channelManager, this._tokenStorage);

  accountpb.AccountServiceClient get _client => _channelManager.accountClient;

  @override
  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    [String? currentRefreshToken]
  ) async {
    Logs().d('AccountRemoteDataSource: смена пароля');
    try {
      final request = accountpb.ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      final refreshToken = currentRefreshToken ?? _tokenStorage.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        request.currentRefreshToken = refreshToken.trim();
      }

      await _client.changePassword(request);
      Logs().i('AccountRemoteDataSource: пароль изменён');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены пароля', e);
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure('Неверные данные');
      }

      throwGrpcError(e, 'Ошибка смены пароля');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    Logs().d('AccountRemoteDataSource: список устройств');
    try {
      final request = accountpb.GetDevicesRequest();
      final response = await _client.getDevices(request);
      final devices = response.devices.map((d) => Device(
        id: d.id,
        createdAt: d.createdAtSeconds.toInt(),
      ))
      .toList();

      Logs().i('AccountRemoteDataSource: получено ${devices.length} устройств');

      return devices;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка списка устройств', e);
      throwGrpcError(e, 'Ошибка загрузки устройств');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    Logs().d('AccountRemoteDataSource: отзыв устройства $deviceId');
    try {
      final request = accountpb.RevokeDeviceRequest(deviceId: deviceId);
      await _client.revokeDevice(request);
      Logs().i('AccountRemoteDataSource: устройство отозвано');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка отзыва устройства', e);
      if (e.code == StatusCode.notFound) {
        throw NetworkFailure('Устройство не найдено');
      }
      throwGrpcError(e, 'Ошибка отзыва устройства');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }
}
