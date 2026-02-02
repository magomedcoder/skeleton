import 'package:flutter/material.dart';
import 'package:legion/domain/entities/runner.dart';

enum RunnerStatus { connected, waiting, disabled }

extension RunnerStatusExtension on RunnerStatus {
  String get label {
    switch (this) {
      case RunnerStatus.connected:
        return 'Подключён';
      case RunnerStatus.waiting:
        return 'Ожидание подключения';
      case RunnerStatus.disabled:
        return 'Отключён';
    }
  }
}

RunnerStatus runnerStatusFromRunner(Runner runner) {
  if (!runner.enabled) return RunnerStatus.disabled;
  if (runner.connected) return RunnerStatus.connected;
  return RunnerStatus.waiting;
}

Color runnerStatusColor(BuildContext context, RunnerStatus status) {
  switch (status) {
    case RunnerStatus.connected:
      return Theme.of(context).colorScheme.primary;
    case RunnerStatus.waiting:
      return Theme.of(context).colorScheme.tertiary;
    case RunnerStatus.disabled:
      return Theme.of(context).colorScheme.outline;
  }
}
