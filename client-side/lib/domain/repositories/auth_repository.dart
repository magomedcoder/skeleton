import 'package:legion/domain/entities/auth_result.dart';
import 'package:legion/domain/entities/auth_tokens.dart';
import 'package:legion/domain/entities/device.dart';

abstract interface class AuthRepository {
  Future<AuthResult> login(String username, String password);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);
}
