import 'dart:convert';

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
  static const _keyUser = 'legion_user';

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
    final userJson = _prefs!.getString(_keyUser);
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
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
    _prefs?.setString(_keyUser, jsonEncode(user.toJson()));
  }

  @override
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _prefs?.remove(_keyAccessToken);
    _prefs?.remove(_keyRefreshToken);
    _prefs?.remove(_keyUser);
  }
}
