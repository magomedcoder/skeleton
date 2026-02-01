import 'package:legion/domain/repositories/runners_repository.dart';

class SetRunnerEnabledUseCase {
  final RunnersRepository _repo;

  SetRunnerEnabledUseCase(this._repo);

  Future<void> call(String address, bool enabled) => _repo.setRunnerEnabled(address, enabled);
}
