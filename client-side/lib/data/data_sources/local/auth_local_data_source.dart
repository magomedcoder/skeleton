import 'package:legion/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  void saveTokens(String accessToken, String refreshToken);

  void saveUser(User user);

  void clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _keyAccessToken = 'legion_access_token';
  static const _keyRefreshToken = 'legion_refresh_token';
  static const _keyUserId = 'legion_user_id';
  static const _keyUserUsername = 'legion_user_username';
  static const _keyUserName = 'legion_user_name';
  static const _keyUserSurname = 'legion_user_surname';
  static const _keyUserRole = 'legion_user_role';

  SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;
  User? _user;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  User? get user => _user;

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _accessToken = _prefs!.getString(_keyAccessToken);
    _refreshToken = _prefs!.getString(_keyRefreshToken);
    final id = _prefs!.getString(_keyUserId);
    final username = _prefs!.getString(_keyUserUsername);
    final name = _prefs!.getString(_keyUserName);
    final surname = _prefs!.getString(_keyUserSurname) ?? '';
    final role = _prefs!.getInt(_keyUserRole);

    if (id != null && username != null && name != null && role != null) {
      _user = User(
        id: id,
        username: username,
        name: name,
        surname: surname,
        role: role,
      );
    } else {
      _user = null;
    }
  }

  @override
  void saveTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _prefs?.setString(_keyAccessToken, accessToken);
    _prefs?.setString(_keyRefreshToken, refreshToken);
  }

  @override
  void saveUser(User user) {
    _user = user;
    _prefs?.setString(_keyUserId, user.id);
    _prefs?.setString(_keyUserUsername, user.username);
    _prefs?.setString(_keyUserName, user.name);
    _prefs?.setString(_keyUserSurname, user.surname);
    _prefs?.setInt(_keyUserRole, user.role);
  }

  @override
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _prefs?.remove(_keyAccessToken);
    _prefs?.remove(_keyRefreshToken);
    _prefs?.remove(_keyUserId);
    _prefs?.remove(_keyUserUsername);
    _prefs?.remove(_keyUserName);
    _prefs?.remove(_keyUserSurname);
    _prefs?.remove(_keyUserRole);
  }
}
