import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/domain/entities/runner.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_event.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_state.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';

class RunnersAdminScreen extends StatefulWidget {
  const RunnersAdminScreen({super.key});

  @override
  State<RunnersAdminScreen> createState() => _RunnersAdminScreenState();
}

class _RunnersAdminScreenState extends State<RunnersAdminScreen> {
  late final RunnersAdminBloc _runnersAdminBloc;

  @override
  void initState() {
    super.initState();
    _runnersAdminBloc = di.sl<RunnersAdminBloc>()..add(const RunnersAdminLoadRequested());
  }

  @override
  void dispose() {
    _runnersAdminBloc.close();
    super.dispose();
  }

  void _showAccessDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Доступ разрешён только администратору'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isAdmin(AuthState state) {
    return state.isAuthenticated && (state.user?.isAdmin ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _runnersAdminBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAdminUser = _isAdmin(authState);

          return BlocListener<RunnersAdminBloc, RunnersAdminState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                context.read<RunnersAdminBloc>().add(
                  const RunnersAdminClearError(),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Раннеры')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isAdminUser)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Этот раздел доступен только администратору.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    if (isAdminUser)
                      Expanded(
                        child: BlocBuilder<RunnersAdminBloc, RunnersAdminState>(
                          builder: (context, runnersState) {
                            if (runnersState.isLoading && runnersState.runners.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (runnersState.runners.isEmpty) {
                              return Center(
                                child: Text(
                                  'Нет зарегистрированных раннеров',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                _runnersAdminBloc.add(
                                  const RunnersAdminLoadRequested(),
                                );
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: runnersState.runners.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  final runner = runnersState.runners[index];
                                  return _RunnerTile(
                                    runner: runner,
                                    onToggle: () {
                                      if (!_isAdmin(authState)) {
                                        _showAccessDenied();
                                        return;
                                      }
                                      _runnersAdminBloc.add(
                                        RunnersAdminSetEnabledRequested(
                                          address: runner.address,
                                          enabled: !runner.enabled,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RunnerTile extends StatelessWidget {
  final Runner runner;
  final VoidCallback onToggle;

  const _RunnerTile({
    required this.runner,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          runner.enabled ? Icons.link : Icons.link_off,
          color: runner.enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          runner.address,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: runner.enabled
              ? null
              : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          runner.enabled ? 'Подключён' : 'Отключён',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: runner.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          ),
        ),
        trailing: Switch(
          value: runner.enabled,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
