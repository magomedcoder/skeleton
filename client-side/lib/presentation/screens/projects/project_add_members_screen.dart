import 'package:flutter/material.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/usecases/search/search_users_usecase.dart';

class ProjectAddMembersScreen extends StatefulWidget {
  final String projectId;
  final List<int> existingMemberIds;

  const ProjectAddMembersScreen({
    super.key,
    required this.projectId,
    required this.existingMemberIds,
  });

  @override
  State<ProjectAddMembersScreen> createState() => _ProjectAddMembersScreenState();
}

class _ProjectAddMembersScreenState extends State<ProjectAddMembersScreen> {
  final _searchController = TextEditingController();
  List<User> _users = const [];
  final Set<String> _selectedIds = {};
  String _query = '';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _search() async {
    final query = _query.trim();
    if (query.isEmpty) {
      setState(() {
        _users = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final usecase = di.sl<SearchUsersUseCase>();
      final (result, _) = await usecase(
        query: query,
        page: 1,
        pageSize: 50,
      );
      setState(() {
        _users = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки пользователей';
      });
    }
  }

  void _toggleUser(User user) {
    final id = user.id;
    final intId = int.tryParse(id);

    if (intId == null) return;

    if (widget.existingMemberIds.contains(intId)) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final ids = _selectedIds
      .map((id) => int.tryParse(id))
      .whereType<int>()
      .toList();
    Navigator.of(context).pop(ids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить участников'),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _confirm,
              child: Text('Добавить (${_selectedIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Имя, фамилия или логин',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _query = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
                _search();
              },
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!)))
          else
            Expanded(
              child: _users.isEmpty
                ? const Center(child: Text('Введите запрос для поиска'))
                : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final intId = int.tryParse(user.id);
                    final isExisting =
                      intId != null &&
                      widget.existingMemberIds.contains(intId);
                    final isSelected = _selectedIds.contains(user.id);

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(user.username),
                      subtitle: Text('${user.name} ${user.surname}'),
                      trailing: isExisting
                        ? const Chip(
                            label: Text('Уже в проекте'),
                            padding: EdgeInsets.zero,
                          )
                        : Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleUser(user),
                        ),
                      onTap: isExisting ? null : () => _toggleUser(user),
                    );
                  },
                ),
            ),
        ],
      ),
    );
  }
}
