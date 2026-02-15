import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:legion/core/log/logs.dart';

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  waitingForNetwork,
  syncing
}

class ConnectionStatusService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  bool _isOnline = true;
  ConnectionStatus _realtimeStatus = ConnectionStatus.disconnected;

  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  ConnectionStatus get currentStatus => _currentStatus;

  ConnectionStatusService() {
    _init();
  }

  Future<void> _init() async {
    await _checkInitialConnectivity();

    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(results);
      _recomputeStatus();
    } catch (e) {
      Logs().e('Ошибка проверки подключения: $e');
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(results);

    if (!wasOnline && _isOnline) {
      Logs().i('Сеть восстановлена');
      _recomputeStatus();
    } else if (wasOnline && !_isOnline) {
      Logs().i('Сеть потеряна');
      _recomputeStatus();
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void setConnecting() {
    _realtimeStatus = ConnectionStatus.connecting;
    _recomputeStatus();
  }

  void setSyncing() {
    _updateStatus(ConnectionStatus.syncing);
  }

  void setWaitingForNetwork() {
    _updateStatus(ConnectionStatus.waitingForNetwork);
  }

  void setConnected() {
    _realtimeStatus = ConnectionStatus.connected;
    _recomputeStatus();
  }

  void setDisconnected() {
    _realtimeStatus = ConnectionStatus.disconnected;
    _recomputeStatus();
  }

  void _recomputeStatus() {
    if (_currentStatus == ConnectionStatus.syncing) {
      _statusController.add(_currentStatus);
      return;
    }

    if (!_isOnline) {
      _updateStatus(ConnectionStatus.waitingForNetwork);
      return;
    }

    _updateStatus(_realtimeStatus);
  }

  void _updateStatus(ConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      Logs().i('Статус подключения изменен: $status');
    }
  }

  Future<void> dispose() async {
    await _statusController.close();
  }
}
