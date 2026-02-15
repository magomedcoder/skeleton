import 'package:legion/domain/entities/device.dart';

abstract interface class AccountRepository {
  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);
}
