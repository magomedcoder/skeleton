import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionModelLocalDataSource {
  Future<String?> getSessionModel(String sessionId);

  Future<void> setSessionModel(String sessionId, String model);

  Future<void> removeSessionModel(String sessionId);
}

class SessionModelLocalDataSourceImpl implements SessionModelLocalDataSource {
  static const _keyPrefix = 'skeleton_session_model_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _key(String sessionId) => '$_keyPrefix$sessionId';

  @override
  Future<String?> getSessionModel(String sessionId) async {
    final prefs = await _preferences;
    return prefs.getString(_key(sessionId));
  }

  @override
  Future<void> setSessionModel(String sessionId, String model) async {
    final prefs = await _preferences;
    await prefs.setString(_key(sessionId), model);
  }

  @override
  Future<void> removeSessionModel(String sessionId) async {
    final prefs = await _preferences;
    await prefs.remove(_key(sessionId));
  }
}
