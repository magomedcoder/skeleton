import 'package:legion/domain/entities/device.dart';
import 'package:legion/domain/repositories/account_repository.dart';

class GetDevicesUseCase {
  final AccountRepository repository;

  GetDevicesUseCase(this.repository);

  Future<List<Device>> call() async {
    return await repository.getDevices();
  }
}
