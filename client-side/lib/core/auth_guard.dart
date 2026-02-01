import 'package:grpc/grpc.dart';
import 'package:legion/core/log/logs.dart';

const accessTokenRefreshThreshold = Duration(minutes: 2);
const backgroundRefreshCheckInterval = Duration(seconds: 60);

class AuthGuard {
  final Future<bool> Function() tryRefresh;
  void Function()? _onSessionExpired;

  AuthGuard(this.tryRefresh, {
    void Function()? onSessionExpired
  }) : _onSessionExpired = onSessionExpired;

  void setOnSessionExpired(void Function()? callback) {
    _onSessionExpired = callback;
  }

  Future<T> execute<T>(
    Future<T> Function() fn, {
    bool skipRetry = false,
  }) async {
    try {
      return await fn();
    } on GrpcError catch (e) {
      if (e.code != StatusCode.unauthenticated || skipRetry) {
        rethrow;
      }
      Logs().d('AuthGuard: unauthenticated, попытка обновить токен');
      final ok = await tryRefresh();
      if (!ok) {
        Logs().w('AuthGuard: рефреш не удался — выход');
        _onSessionExpired?.call();
        rethrow;
      }
      try {
        return await fn();
      } on GrpcError catch (e2) {
        if (e2.code == StatusCode.unauthenticated) {
          Logs().w('AuthGuard: снова unauthenticated после рефреша — выход');
          _onSessionExpired?.call();
        }
        rethrow;
      }
    }
  }
}
