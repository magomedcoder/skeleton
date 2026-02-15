import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/core/date_formatter.dart';
import 'package:legion/domain/entities/project_activity.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/usecases/project/get_project_history_usecase.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';

class ProjectHistoryView extends StatefulWidget {
  final String projectId;

  const ProjectHistoryView({super.key, required this.projectId});

  @override
  State<ProjectHistoryView> createState() => _ProjectHistoryViewState();
}

class _ProjectHistoryViewState extends State<ProjectHistoryView> {
  List<ProjectActivity> _items = [];
  List<User>? _members;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadMembers();
  }

  void _loadMembers() {
    try {
      context.read<ProjectBloc>().add(
        ProjectMembersLoadRequested(widget.projectId),
      );
      context.read<ProjectBloc>().stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() => _members = state.members);
        }
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await di.sl<GetProjectHistoryUseCase>()(widget.projectId);
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getUserName(int userId) {
    if (_members == null) return 'ID: $userId';
    final user = _members!.firstWhere(
      (u) => u.id == userId.toString(),
      orElse: () => User(
        id: userId.toString(),
        username: '',
        name: '',
        surname: '',
        role: 0,
      ),
    );

    return user.username.isNotEmpty
      || user.name.isNotEmpty
      || user.surname.isNotEmpty
        ? user.displayName
        : 'ID: $userId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('История'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Нет записей в истории',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final a = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.actionLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (a.payload.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          a.payload,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormatter.formatDate(a.createdAt)} · ${_getUserName(a.userId)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
