import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/date_formatter.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_event.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_state.dart';

class DevicesContent extends StatelessWidget {
  const DevicesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<DevicesBloc>();
    return BlocConsumer<DevicesBloc, DevicesState>(
      listenWhen: (_, current) => current is DevicesError,
      listener: (context, state) {
        if (state is DevicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DevicesLoading || state is DevicesInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DevicesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => bloc.add(const DevicesLoadRequested()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is DevicesLoaded
          || state is DevicesRevoking
          || state is DevicesRevokeFailed) {
          final devices = switch (state) {
            DevicesLoaded(devices: final d) => d,
            DevicesRevoking(devices: final d) => d,
            DevicesRevokeFailed(devices: final d) => d,
            _ => <Device>[],
          };

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other_rounded,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет активных сессий',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final isRevoking = state is DevicesRevoking;
          final revokingId = isRevoking ? (state).revokingDeviceId : null;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final revoking = revokingId == device.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.smartphone_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'Устройство',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Вход: ${DateFormatter.formatDate(device.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: revoking
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : TextButton(
                      onPressed: () =>
                          bloc.add(DevicesRevokeRequested(device)),
                      child: const Text('Выйти'),
                    ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
