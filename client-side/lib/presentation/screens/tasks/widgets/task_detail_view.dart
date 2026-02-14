import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/task_comment.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/repositories/project_repository.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/widgets/code_block_builder.dart';

class TaskDetailView extends StatefulWidget {
  final Task task;
  final String projectId;
  final VoidCallback? onBack;

  const TaskDetailView({
    super.key,
    required this.task,
    required this.projectId,
    this.onBack,
  });

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  List<User>? _members;
  List<TaskComment> _comments = [];
  bool _commentsLoading = false;
  final TextEditingController _commentController = TextEditingController();
  bool _commentSending = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _commentsLoading = true);
    try {
      final repo = di.sl<ProjectRepository>();
      final list = await repo.getTaskComments(widget.task.id);
      if (mounted) setState(() => _comments = list);
    } catch (_) {
      if (mounted) setState(() => _comments = []);
    } finally {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _commentSending) return;
    setState(() => _commentSending = true);
    try {
      final repo = di.sl<ProjectRepository>();
      await repo.addTaskComment(widget.task.id, text);
      _commentController.clear();
      await _loadComments();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить комментарий')),
        );
      }
    } finally {
      if (mounted) setState(() => _commentSending = false);
    }
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.projectId));
      
      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members;
          });
        }
      });
    } catch (e) {

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
    
    final name = '${user.name} ${user.surname}'.trim();
    return name.isNotEmpty ? name : user.username.isNotEmpty ? '@${user.username}' : 'ID: $userId';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.task.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (widget.task.description.isNotEmpty) ...[
            Text(
              'Описание',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MarkdownBody(
                data: widget.task.description,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge,
                  h1: Theme.of(context).textTheme.headlineSmall,
                  h2: Theme.of(context).textTheme.titleLarge,
                  h3: Theme.of(context).textTheme.titleMedium,
                  listIndent: 24,
                  blockquote: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  code: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                builders: {'pre': CodeBlockBuilder()},
              ),
            ),
            const SizedBox(height: 24),
          ],
          _InfoRow(
            label: 'Создано',
            value: _formatDate(widget.task.createdAt),
            icon: Icons.access_time,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Постановщик',
            value: _getUserName(widget.task.assigner),
            icon: Icons.person_add,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Исполнитель',
            value: _getUserName(widget.task.executor),
            icon: Icons.person,
          ),
          const SizedBox(height: 24),
          Text(
            'Комментарии',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_commentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            ..._comments.map(
              (c) => _CommentTile(
                comment: c,
                userName: _getUserName(c.userId),
                formatDate: _formatDate,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Написать комментарий...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _commentSending
                    ? null
                    : () => _sendComment(),
                  child: _commentSending
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Отправить'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final TaskComment comment;
  final String userName;
  final String Function(int) formatDate;

  const _CommentTile({
    required this.comment,
    required this.userName,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDate(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            comment.body,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
