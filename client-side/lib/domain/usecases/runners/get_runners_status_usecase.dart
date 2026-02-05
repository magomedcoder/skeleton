import 'package:skeleton/domain/repositories/runners_repository.dart';

class GetRunnersStatusUseCase {
  final RunnersRepository _repo;

  GetRunnersStatusUseCase(this._repo);

  Future<bool> call() => _repo.getRunnersStatus();
}
