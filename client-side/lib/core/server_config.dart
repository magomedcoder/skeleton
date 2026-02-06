import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _keyHost = 'skeleton_server_host';
  static const _keyPort = 'skeleton_server_port';

  String _host = '';
  int _port = 0;
  SharedPreferences? _prefs;

  String get host => _host;
  int get port => _port;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _host = _prefs!.getString(_keyHost) ?? '';
    _port = _prefs!.getInt(_keyPort) ?? 0;
  }

  Future<void> setServer(String host, int port) async {
    if (_host == host && _port == port) return;
    _host = host;
    _port = port;
    await _prefs?.setString(_keyHost, host);
    await _prefs?.setInt(_keyPort, port);
  }
}
