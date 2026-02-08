import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:legion/core/log/logs.dart';

const accessTokenRefreshThreshold = Duration(minutes: 2);
const backgroundRefreshCheckInterval = Duration(seconds: 60);

class AuthGuard {
  final Future<bool> Function() tryRefresh;
  void Function()? _onSessionExpired;

  Future<bool>? _refreshInProgress;
  bool _sessionExpiredCalled = false;

  AuthGuard(this.tryRefresh, {
    void Function()? onSessionExpired
  }) : _onSessionExpired = onSessionExpired;

  void setOnSessionExpired(void Function()? callback) {
    _onSessionExpired = callback;
    _sessionExpiredCalled = false;
  }

  Future<bool> _doRefresh() async {
    if (_refreshInProgress != null) {
      Logs().d('AuthGuard: ожидание завершения текущего рефреша');
      return _refreshInProgress!;
    }

    final completer = Completer<bool>();
    _refreshInProgress = completer.future;

    try {
      final ok = await tryRefresh();
      completer.complete(ok);
      return ok;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _refreshInProgress = null;
    }
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
      final ok = await _doRefresh();
      if (!ok) {
        Logs().w('AuthGuard: рефреш не удался - выход');
        if (!_sessionExpiredCalled) {
          _sessionExpiredCalled = true;
          _onSessionExpired?.call();
        }
        rethrow;
      }
      try {
        return await fn();
      } on GrpcError catch (e2) {
        if (e2.code == StatusCode.unauthenticated) {
          Logs().w('AuthGuard: снова unauthenticated после рефреша - выход');
          if (!_sessionExpiredCalled) {
            _sessionExpiredCalled = true;
            _onSessionExpired?.call();
          }
        }
        rethrow;
      }
    }
  }
}
