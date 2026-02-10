import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/usecases/search/search_users_usecase.dart';
import 'package:legion/presentation/screens/user_chat/bloc/user_chat_bloc.dart';
import 'package:legion/presentation/screens/user_chat/bloc/user_chat_event.dart';

class ChatUserSearchScreen extends StatefulWidget {
  const ChatUserSearchScreen({super.key});

  @override
  State<ChatUserSearchScreen> createState() => _ChatUserSearchScreenState();
}

class _ChatUserSearchScreenState extends State<ChatUserSearchScreen> {
  final _searchController = TextEditingController();
  List<User> _users = const [];
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
      final (result, _) = await usecase(query: query, page: 1, pageSize: 50);
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

  void _onUserTap(User user) {
    final bloc = context.read<ChatBloc>();
    bloc.add(ChatOpenWithUser(user.id.toString()));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Найти пользователя')),
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
            const Expanded(
                child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
                child: Center(child: Text(_error!)),
            )
          else
            Expanded(
              child: _users.isEmpty
                ? const Center(child: Text('Пользователи не найдены'))
                : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(user.username),
                      subtitle: Text('${user.name} ${user.surname}'),
                      onTap: () => _onUserTap(user),
                    );
                  },
                ),
            ),
        ],
      ),
    );
  }
}
