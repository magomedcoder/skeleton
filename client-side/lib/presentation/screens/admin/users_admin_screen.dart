import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/injector.dart' as di;
import 'package:skeleton/domain/entities/user.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_bloc.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_event.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_state.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_state.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  late final UsersAdminBloc _usersAdminBloc;

  @override
  void initState() {
    super.initState();
    _usersAdminBloc = di.sl<UsersAdminBloc>()..add(const UsersAdminLoadRequested());
  }

  @override
  void dispose() {
    _usersAdminBloc.close();
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
    final user = state.user;
    return state.isAuthenticated && user?.isAdmin == true;
  }

  Future<void> _createUserDialog(AuthState authState) async {
    if (!_isAdmin(authState)) {
      _showAccessDenied();
      return;
    }

    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    int selectedRole = 0;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Создать пользователя'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите логин';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.trim().length < 8) {
                    return 'Минимум 8 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setInnerState) {
                  return DropdownButtonFormField<int>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Роль',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Пользователь'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Администратор'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setInnerState(() {
                        selectedRole = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              _usersAdminBloc.add(
                UsersAdminCreateRequested(
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  surname: surnameController.text.trim(),
                  role: selectedRole,
                ),
              );

              Navigator.of(ctx).pop();
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUserDialog(AuthState authState, User user) async {
    if (!_isAdmin(authState)) {
      _showAccessDenied();
      return;
    }

    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController();
    final nameController = TextEditingController(text: user.name);
    final surnameController = TextEditingController(text: user.surname);
    int selectedRole = user.role;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать пользователя'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите логин';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый пароль (необязательно)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (value.trim().length < 8) return 'Минимум 8 символов';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setInnerState) {
                  return DropdownButtonFormField<int>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Роль',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Пользователь'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Администратор'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setInnerState(() {
                        selectedRole = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              _usersAdminBloc.add(
                UsersAdminUpdateRequested(
                  id: user.id,
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  surname: surnameController.text.trim(),
                  role: selectedRole,
                ),
              );

              Navigator.of(ctx).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _usersAdminBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAdminUser = _isAdmin(authState);

          return BlocListener<UsersAdminBloc, UsersAdminState>(
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
                context.read<UsersAdminBloc>().add(
                  const UsersAdminClearError(),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Пользователи'),
                actions: [
                  if (isAdminUser)
                    IconButton(
                      tooltip: 'Создать пользователя',
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      onPressed: () => _createUserDialog(authState),
                    ),
                ],
              ),
              body: BlocBuilder<UsersAdminBloc, UsersAdminState>(
                builder: (context, usersState) {
                  final users = usersState.users;

                  return Padding(
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
                        if (isAdminUser && usersState.isLoading && users.isEmpty)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (isAdminUser && users.isEmpty)
                          const Expanded(child: SizedBox())
                        else if (isAdminUser)
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                _usersAdminBloc.add(
                                  const UsersAdminLoadRequested(),
                                );
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: users.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  final user = users[index];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          user.name.isNotEmpty
                                            ? user.name.characters.first.toUpperCase()
                                            : user.username.characters.first.toUpperCase(),
                                        ),
                                      ),
                                      title: Text(
                                        ('${user.name} ${user.surname}').trim().isNotEmpty
                                            ? ('${user.name} ${user.surname}').trim()
                                            : user.username,
                                      ),
                                      subtitle: Text('@${user.username}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Редактировать',
                                        onPressed: () => _editUserDialog(authState, user),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
