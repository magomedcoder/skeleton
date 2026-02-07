import 'package:skeleton/domain/entities/device.dart';
import 'package:skeleton/domain/repositories/auth_repository.dart';

class GetDevicesUseCase {
  final AuthRepository repository;

  GetDevicesUseCase(this.repository);

  Future<List<Device>> call() async {
    return await repository.getDevices();
  }
}
