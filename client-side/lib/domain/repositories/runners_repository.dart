import 'package:legion/domain/entities/runner.dart';

abstract class RunnersRepository {
  Future<List<Runner>> getRunners();

  Future<void> setRunnerEnabled(String address, bool enabled);

  Future<bool> getRunnersStatus();
}
