import 'package:legion/domain/entities/account_update.dart';
import 'package:legion/domain/entities/device.dart';

abstract interface class AccountRepository {
  Future<Stream<AccountUpdate>> getUpdates();

  Future<void> changePassword(String oldPassword, String newPassword, [String? currentRefreshToken]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);
}
