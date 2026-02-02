import 'package:flutter/material.dart';
import 'package:legion/domain/entities/runner.dart';
import 'package:legion/presentation/screens/admin/widgets/runner_card_header.dart';
import 'package:legion/presentation/screens/admin/widgets/runner_gpu_section.dart';
import 'package:legion/presentation/screens/admin/widgets/runner_server_info_section.dart';
import 'package:legion/presentation/screens/admin/widgets/runner_status.dart';

class RunnerCard extends StatelessWidget {
  final Runner runner;
  final VoidCallback onToggleEnabled;

  const RunnerCard({
    super.key,
    required this.runner,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final status = runnerStatusFromRunner(runner);
    final hasServerInfo = runner.serverInfo != null;
    final hasGpus = runner.gpus.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            RunnerCardHeader(
              runner: runner,
              status: status,
              onToggleEnabled: onToggleEnabled,
            ),
            if (hasServerInfo) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              RunnerServerInfoSection(serverInfo: runner.serverInfo!),
            ],
            if (hasGpus) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              RunnerGpuSection(gpus: runner.gpus),
            ],
          ],
        ),
      ),
    );
  }
}
