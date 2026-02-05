import 'package:flutter/material.dart';
import 'package:skeleton/domain/entities/gpu_info.dart';

class RunnerGpuSection extends StatelessWidget {
  final List<GpuInfo> gpus;

  const RunnerGpuSection({
    super.key,
    required this.gpus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Видеокарта',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ...gpus.map((g) => RunnerGpuInfoRow(gpu: g)),
      ],
    );
  }
}

class RunnerGpuInfoRow extends StatelessWidget {
  final GpuInfo gpu;

  const RunnerGpuInfoRow({
    super.key,
    required this.gpu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            gpu.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              RunnerGpuMetric(
                icon: Icons.thermostat,
                label: 'Температура',
                value: '${gpu.temperatureC} °C',
              ),
              RunnerGpuMetric(
                icon: Icons.memory,
                label: 'Память',
                value: '${gpu.memoryUsedMb} / ${gpu.memoryTotalMb} МБ',
              ),
              if (gpu.utilizationPercent > 0)
                RunnerGpuMetric(
                  icon: Icons.speed,
                  label: 'Загрузка',
                  value: '${gpu.utilizationPercent} %',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RunnerGpuMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RunnerGpuMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
