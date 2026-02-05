import 'package:skeleton/data/data_sources/remote/runners_remote_datasource.dart';
import 'package:skeleton/domain/entities/runner.dart';
import 'package:skeleton/domain/repositories/runners_repository.dart';

class RunnersRepositoryImpl implements RunnersRepository {
  final IRunnersRemoteDataSource _remote;

  RunnersRepositoryImpl(this._remote);

  @override
  Future<List<Runner>> getRunners() => _remote.getRunners();

  @override
  Future<void> setRunnerEnabled(String address, bool enabled) => _remote.setRunnerEnabled(address, enabled);

  @override
  Future<bool> getRunnersStatus() => _remote.getRunnersStatus();
}
