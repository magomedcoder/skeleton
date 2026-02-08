import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';

class ProfileOverviewWidget extends StatelessWidget {
  const ProfileOverviewWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final displayName = user != null
          ? ('${user.name} ${user.surname}'.trim().isNotEmpty
            ? '${user.name} ${user.surname}'.trim()
            : 'Пользователь')
          : 'Пользователь';
        final username = user != null ? '@${user.username}' : '';

        final content = Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        if (scrollable) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }
}
