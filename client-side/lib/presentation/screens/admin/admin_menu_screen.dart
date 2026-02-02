import 'package:flutter/material.dart';

class AdminMenuScreen extends StatelessWidget {
  final VoidCallback onSelectRunners;
  final VoidCallback onSelectUsers;

  const AdminMenuScreen({
    super.key,
    required this.onSelectRunners,
    required this.onSelectUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.dns_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Раннеры'),
              subtitle: const Text('Управление раннерами'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSelectRunners,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.supervisor_account_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Пользователи'),
              subtitle: const Text('Управление пользователями'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSelectUsers,
            ),
          ),
        ],
      ),
    );
  }
}
