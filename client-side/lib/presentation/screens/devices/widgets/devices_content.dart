import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/domain/entities/device.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_event.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_state.dart';

class DevicesContent extends StatelessWidget {
  const DevicesContent({super.key});

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DevicesBloc>();
    return BlocConsumer<DevicesBloc, DevicesState>(
      listenWhen: (_, current) => current is DevicesError,
      listener: (context, state) {
        if (state is DevicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
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
        if (state is DevicesLoaded ||
            state is DevicesRevoking ||
            state is DevicesRevokeFailed) {
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
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет активных сессий',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.smartphone_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'Устройство',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Вход: ${_formatDate(device.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
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
