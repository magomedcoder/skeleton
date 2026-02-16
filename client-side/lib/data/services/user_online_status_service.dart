import 'dart:async';

class UserOnlineStatusService {
  final Map<String, bool> _status = {};
  final StreamController<Map<String, bool>> _controller = StreamController<Map<String, bool>>.broadcast();

  Stream<Map<String, bool>> get statusStream => _controller.stream;

  Map<String, bool> get statusMap => Map.from(_status);

  bool? isOnline(String userId) => _status[userId];

  void setUserOnline(String userId, bool online) {
    if (_status[userId] == online) return;
    _status[userId] = online;
    _controller.add(statusMap);
  }

  void dispose() {
    _controller.close();
  }
}
