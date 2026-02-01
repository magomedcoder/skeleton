import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/domain/entities/runner.dart';
import 'package:legion/generated/grpc_pb/runner.pb.dart' as runner_pb;

abstract class IRunnersRemoteDataSource {
  Future<List<Runner>> getRunners();

  Future<void> setRunnerEnabled(String address, bool enabled);

  Future<bool> getRunnersStatus();
}

class RunnersRemoteDataSource implements IRunnersRemoteDataSource {
  final GrpcChannelManager _channelManager;

  RunnersRemoteDataSource(this._channelManager);

  @override
  Future<List<Runner>> getRunners() async {
    try {
      final response = await _channelManager.runnerAdminClient.getRunners(
        runner_pb.Empty(),
      );
      return response.runners
        .map((r) => Runner(address: r.address, enabled: r.enabled))
        .toList();
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        throw NetworkFailure('Ошибка подключения gRPC');
      }

      if (e.code == StatusCode.permissionDenied) {
        throw NetworkFailure('Доступ разрешён только администратору');
      }

      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка получения списка раннеров: $e');
    }
  }

  @override
  Future<void> setRunnerEnabled(String address, bool enabled) async {
    try {
      await _channelManager.runnerAdminClient.setRunnerEnabled(
        runner_pb.SetRunnerEnabledRequest(
          address: address,
          enabled: enabled
        ),
      );
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        throw NetworkFailure('Ошибка подключения gRPC');
      }

      if (e.code == StatusCode.permissionDenied) {
        throw NetworkFailure('Доступ разрешён только администратору');
      }

      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка изменения состояния раннера: $e');
    }
  }

  @override
  Future<bool> getRunnersStatus() async {
    try {
      final response = await _channelManager.runnerAdminClient.getRunnersStatus(
        runner_pb.Empty(),
      );
      return response.hasActiveRunners;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unimplemented) {
        return true;
      }
      if (e.code == StatusCode.unavailable) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
