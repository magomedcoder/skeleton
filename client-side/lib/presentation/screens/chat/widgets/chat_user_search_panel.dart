import 'package:flutter/material.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/usecases/search/search_users_usecase.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_list_avatar.dart';

class ChatUserSearchPanel extends StatefulWidget {
  final void Function(User user) onUserSelected;
  final VoidCallback? onClose;

  const ChatUserSearchPanel({
    super.key,
    required this.onUserSelected,
    this.onClose,
  });

  @override
  State<ChatUserSearchPanel> createState() => _ChatUserSearchPanelState();
}

class _ChatUserSearchPanelState extends State<ChatUserSearchPanel> {
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
      if (mounted) {
        setState(() {
          _users = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка загрузки пользователей';
        });
      }
    }
  }

  void _onUserTap(User user) {
    widget.onUserSelected(user);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Имя, фамилия или логин',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              suffixIcon: _query.isNotEmpty
                ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _searchController.clear();
                    });
                    _search();
                  },
                )
                : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: (value) {
              setState(() => _query = value);
              _search();
            },
          ),
        ),
        Expanded(child: _buildList(theme)),
      ],
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(
          'Введите запрос для поиска',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Пользователи не найдены',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _users.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 60,
        color: theme.colorScheme.outline.withValues(alpha: 0.12),
      ),
      itemBuilder: (context, index) {
        final user = _users[index];
        final title = user.displayName;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onUserTap(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  ChatListAvatar(
                    title: user.name.isNotEmpty
                      ? user.name
                      : (user.username.isNotEmpty ? user.username : '?'),
                    isOnline: false,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.username.isNotEmpty
                            ? '@${user.username}'
                            : title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.name.isNotEmpty ||
                            user.surname.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${user.name} ${user.surname}'.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
