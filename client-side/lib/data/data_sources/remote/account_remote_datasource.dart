import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:legion/core/connection_status.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/core/reconnect_policy.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/generated/grpc_pb/account.pbgrpc.dart' as accountpb;

abstract class IAccountRemoteDataSource {
  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);

  Stream<accountpb.UpdateResponse> getUpdates();
}

class AccountRemoteDataSource implements IAccountRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final UserLocalDataSourceImpl _userLocal;
  final ConnectionStatusService? connectionStatusService;

  AccountRemoteDataSource(
    this._channelManager,
    this._userLocal,
    this.connectionStatusService,
  );

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
      final refreshToken = currentRefreshToken ?? _userLocal.refreshToken;
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

  @override
  Stream<accountpb.UpdateResponse> getUpdates() async* {
    const policy = ReconnectPolicy.hybrid();
    int attempt = 0;

    while (true) {
      final reqCtrl = StreamController<accountpb.UpdateRequest>();
      Timer? pingTimer;
      Duration pingInterval = const Duration(seconds: 30);
      bool connectedOnceThisAttempt = false;

      void startPinging() {
        pingTimer?.cancel();
        pingTimer = Timer.periodic(pingInterval, (_) {
          if (!reqCtrl.isClosed) {
            reqCtrl.add(
              accountpb.UpdateRequest(
                systemPingEvent: accountpb.UpdateSystemPingEvent(),
              ),
            );
          }
        });
      }

      try {
        connectionStatusService?.setConnecting();
        startPinging();

        final syncState = await _userLocal.getSyncState();
        final currentPts = syncState['pts'] ?? 0;
        final currentDate = syncState['date'] ?? 0;

        reqCtrl.add(accountpb.UpdateRequest(
          state: accountpb.UpdateState(
            pts: Int64(currentPts),
            date: Int64(currentDate),
          ),
        ));

        Stream<accountpb.UpdateResponse> respStream = _client.getUpdates(reqCtrl.stream);

        await for (final ev in respStream) {
          attempt = 0;
          if (!connectedOnceThisAttempt) {
            connectedOnceThisAttempt = true;
            connectionStatusService?.setConnected();
          }

          if (ev.hasState()) {
            await _userLocal.setSyncState(
              ev.state.pts.toInt(),
              ev.state.date.toInt(),
            );
          }

          final updateSystem = ev.updateSystem;
          if (updateSystem.hasSystemPingIntervalEvent()) {
            final s = int.tryParse(updateSystem.systemPingIntervalEvent.pingInterval) ?? 30;
            pingInterval = Duration(seconds: s);
            startPinging();
          }

          if (updateSystem.hasSystemPingEvent()) {
            if (!reqCtrl.isClosed) {
              reqCtrl.add(accountpb.UpdateRequest(
                systemPongEvent: accountpb.UpdateSystemPongEvent(),
              ));
            }
          }

          yield ev;
        }

        final wait = policy.next(attempt);
        attempt++;
        connectionStatusService?.setDisconnected();
        Logs().i('getUpdates - дисконнект - переподключение ${wait.inMilliseconds} - $attempt');
        await Future.delayed(wait);
        continue;
      } catch (e) {
        final wait = policy.next(attempt);
        attempt++;
        connectionStatusService?.setDisconnected();
        Logs().e('getUpdates error: $e | переподключение ${wait.inMilliseconds} - $attempt');
        await Future.delayed(wait);
        continue;
      } finally {
        pingTimer?.cancel();
        reqCtrl.close();
        Logs().i('Ресурсы потока очищены');
      }
    }
  }
}
