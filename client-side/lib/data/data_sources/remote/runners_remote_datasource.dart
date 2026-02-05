import 'package:grpc/grpc.dart';
import 'package:skeleton/core/auth_guard.dart';
import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/grpc_channel_manager.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/domain/entities/gpu_info.dart';
import 'package:skeleton/domain/entities/runner.dart';
import 'package:skeleton/domain/entities/server_info.dart';
import 'package:skeleton/generated/grpc_pb/runner.pb.dart' as runner_pb;

abstract class IRunnersRemoteDataSource {
  Future<List<Runner>> getRunners();

  Future<void> setRunnerEnabled(String address, bool enabled);

  Future<bool> getRunnersStatus();
}

class RunnersRemoteDataSource implements IRunnersRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  RunnersRemoteDataSource(this._channelManager, this._authGuard);

  @override
  Future<List<Runner>> getRunners() async {
    Logs().d('RunnersRemoteDataSource: получение списка раннеров');
    try {
      final response = await _authGuard.execute(
        () => _channelManager.runnerAdminClient.getRunners(
          runner_pb.Empty(),
        ),
      );
      final runners = response.runners
        .map((r) => Runner(
          address: r.address,
          enabled: r.enabled,
          connected: r.hasConnected() ? r.connected : false,
          gpus: r.gpus.map(_gpuFromProto).toList(),
          serverInfo: r.hasServerInfo() ? _serverInfoFromProto(r.serverInfo) : null,
        ))
        .toList();
      Logs().i('RunnersRemoteDataSource: получено раннеров: ${runners.length}');
      return runners;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        Logs().w('RunnersRemoteDataSource: сервер недоступен');
        throw NetworkFailure('Ошибка подключения');
      }

      if (e.code == StatusCode.permissionDenied) {
        Logs().w('RunnersRemoteDataSource: доступ запрещён');
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      Logs().e('RunnersRemoteDataSource: ошибка получения раннеров', e);
      throw NetworkFailure('Ошибка получения списка раннеров');
    } catch (e) {
      Logs().e('RunnersRemoteDataSource: ошибка получения раннеров', e);
      throw ApiFailure('Ошибка получения списка раннеров');
    }
  }

  static GpuInfo _gpuFromProto(runner_pb.GpuInfo p) {
    return GpuInfo(
      name: p.name,
      temperatureC: p.temperatureC,
      memoryTotalMb: p.memoryTotalMb.toInt(),
      memoryUsedMb: p.memoryUsedMb.toInt(),
      utilizationPercent: p.utilizationPercent,
    );
  }

  static ServerInfo _serverInfoFromProto(runner_pb.ServerInfo p) {
    return ServerInfo(
      hostname: p.hostname,
      os: p.os,
      arch: p.arch,
      cpuCores: p.cpuCores,
      memoryTotalMb: p.memoryTotalMb.toInt(),
      models: p.models.toList(),
    );
  }

  @override
  Future<void> setRunnerEnabled(String address, bool enabled) async {
    Logs().d('RunnersRemoteDataSource: setRunnerEnabled $address enabled=$enabled');
    try {
      await _authGuard.execute(
        () => _channelManager.runnerAdminClient.setRunnerEnabled(
          runner_pb.SetRunnerEnabledRequest(
            address: address,
            enabled: enabled
          ),
        ),
      );
      Logs().i('RunnersRemoteDataSource: состояние раннера обновлено');
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        Logs().w('RunnersRemoteDataSource: сервер недоступен');
        throw NetworkFailure('Ошибка подключения');
      }

      if (e.code == StatusCode.permissionDenied) {
        Logs().w('RunnersRemoteDataSource: доступ запрещён');
        throw NetworkFailure('Доступ разрешён только администратору');
      }
      Logs().e('RunnersRemoteDataSource: ошибка изменения состояния раннера', e);
      throw NetworkFailure('Ошибка изменения состояния раннера');
    } catch (e) {
      Logs().e('RunnersRemoteDataSource: ошибка изменения состояния раннера', e);
      throw ApiFailure('Ошибка изменения состояния раннера');
    }
  }

  @override
  Future<bool> getRunnersStatus() async {
    Logs().v('RunnersRemoteDataSource: проверка статуса раннеров');
    try {
      final response = await _authGuard.execute(
        () => _channelManager.runnerAdminClient.getRunnersStatus(
          runner_pb.Empty(),
        ),
      );
      return response.hasActiveRunners;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unimplemented) {
        Logs().d('RunnersRemoteDataSource: getRunnersStatus не реализован');
        return true;
      }
      if (e.code == StatusCode.unavailable) {
        Logs().w('RunnersRemoteDataSource: сервер недоступен при проверке статуса');
        return false;
      }
      return false;
    } catch (e) {
      Logs().e('RunnersRemoteDataSource: ошибка проверки статуса', e);
      return false;
    }
  }
}
