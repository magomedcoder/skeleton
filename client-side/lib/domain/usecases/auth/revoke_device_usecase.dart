import 'package:legion/domain/repositories/auth_repository.dart';

class RevokeDeviceUseCase {
  final AuthRepository repository;

  RevokeDeviceUseCase(this.repository);

  Future<void> call(int deviceId) async {
    return await repository.revokeDevice(deviceId);
  }
}
