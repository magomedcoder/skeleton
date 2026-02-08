import 'package:legion/domain/entities/runner.dart';
import 'package:legion/domain/repositories/runners_repository.dart';

class GetRunnersUseCase {
  final RunnersRepository _repo;

  GetRunnersUseCase(this._repo);

  Future<List<Runner>> call() => _repo.getRunners();
}
