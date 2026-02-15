import 'package:legion/domain/repositories/account_repository.dart';

class RevokeDeviceUseCase {
  final AccountRepository repository;

  RevokeDeviceUseCase(this.repository);

  Future<void> call(int deviceId) async {
    return await repository.revokeDevice(deviceId);
  }
}
