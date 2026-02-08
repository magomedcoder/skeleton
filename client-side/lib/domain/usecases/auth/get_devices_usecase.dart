import 'package:legion/domain/entities/device.dart';
import 'package:legion/domain/repositories/auth_repository.dart';

class GetDevicesUseCase {
  final AuthRepository repository;

  GetDevicesUseCase(this.repository);

  Future<List<Device>> call() async {
    return await repository.getDevices();
  }
}
