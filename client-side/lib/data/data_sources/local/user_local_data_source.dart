import 'package:flutter/material.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UserLocalDataSource {
  String? get accessToken;
  String? get refreshToken;
  User? get user;
  bool get hasToken;

  void saveTokens(String accessToken, String refreshToken);
  void saveUser(User user);
  void clearTokens();

  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  int getAccentColorId();
  Future<void> setAccentColorId(int id);

  Future<void> init();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const _keyAccessToken = 'legion_access_token';
  static const _keyRefreshToken = 'legion_refresh_token';
  static const _keyUserId = 'legion_user_id';
  static const _keyUserUsername = 'legion_user_username';
  static const _keyUserName = 'legion_user_name';
  static const _keyUserSurname = 'legion_user_surname';
  static const _keyUserRole = 'legion_user_role';
  static const _keyThemeMode = 'legion_theme_mode';
  static const _keyAccentColorId = 'legion_accent_color_id';

  SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;
  User? _user;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  User? get user => _user;

  @override
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  @override
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

  @override
  ThemeMode getThemeMode() {
    final index = _prefs?.getInt(_keyThemeMode);
    if (index == null) {
      return ThemeMode.light;
    }

    if (index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.light;
    }

    return ThemeMode.values[index];
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setInt(_keyThemeMode, mode.index);
  }

  @override
  int getAccentColorId() {
    final id = _prefs?.getInt(_keyAccentColorId);
    if (id == null || id < 0) return 0;
    return id;
  }

  @override
  Future<void> setAccentColorId(int id) async {
    await _prefs?.setInt(_keyAccentColorId, id);
  }
}
