import 'package:flutter/material.dart';
import 'package:legion/domain/entities/server_info.dart';

class RunnerServerInfoSection extends StatelessWidget {
  final ServerInfo serverInfo;

  const RunnerServerInfoSection({
    super.key,
    required this.serverInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Сервер',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (serverInfo.hostname.isNotEmpty)
              RunnerInfoChip(
                icon: Icons.computer,
                label: 'Хост',
                value: serverInfo.hostname,
              ),
            if (serverInfo.os.isNotEmpty)
              RunnerInfoChip(
                icon: Icons.terminal,
                label: 'ОС',
                value: '${serverInfo.os}/${serverInfo.arch}',
              ),
            if (serverInfo.cpuCores > 0)
              RunnerInfoChip(
                icon: Icons.memory,
                label: 'Ядра CPU',
                value: '${serverInfo.cpuCores}',
              ),
            if (serverInfo.memoryTotalMb > 0)
              RunnerInfoChip(
                icon: Icons.storage,
                label: 'ОЗУ',
                value: '${serverInfo.memoryTotalMb} МБ',
              ),
          ],
        ),
        if (serverInfo.models.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Модели',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: serverInfo.models.map((m) => Chip(
              label: Text(m, style: theme.textTheme.labelSmall),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ],
    );
  }
}

class RunnerInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RunnerInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
