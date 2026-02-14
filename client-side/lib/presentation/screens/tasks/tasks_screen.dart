import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/repositories/project_repository.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_event.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_state.dart';
import 'package:legion/presentation/screens/tasks/widgets/board.dart';
import 'package:legion/presentation/screens/tasks/widgets/column_edit_dialog.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_create_dialog.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_detail_dialog.dart';

class TasksScreen extends StatefulWidget {
  final Project project;

  const TasksScreen({super.key, required this.project});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<BoardColumn>? _columns;
  bool _columnsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
      _loadColumns();
    });
  }

  Future<void> _loadColumns() async {
    setState(() => _columnsLoading = true);
    try {
      final repo = di.sl<ProjectRepository>();
      final list = await repo.getProjectColumns(widget.project.id);
      if (mounted) setState(() => _columns = list..sort((a, b) => a.position.compareTo(b.position)));
    } catch (_) {
      if (mounted) setState(() => _columns = const []);
    } finally {
      if (mounted) setState(() => _columnsLoading = false);
    }
  }

  void _showCreateColumnDialog() {
    ColumnEditDialog.showCreate(
      context,
      onSave: (title, colorHex) async {
        final repo = di.sl<ProjectRepository>();
        await repo.createProjectColumn(widget.project.id, title, colorHex);
        await _loadColumns();
      },
    );
  }

  void _showEditColumnDialog(BoardColumn column) {
    ColumnEditDialog.showEdit(
      context,
      column: column,
      onSave: (title, colorHex) async {
        final repo = di.sl<ProjectRepository>();
        await repo.editProjectColumn(column.id, title: title, color: colorHex);
        await _loadColumns();
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final taskBloc = context.read<TaskBloc>();
    ProjectBloc? projectBloc;
    try {
      projectBloc = context.read<ProjectBloc>();
    } catch (e) {

    }
    
    showDialog<void>(
      context: context,
      builder: (ctx) {
        Widget dialog = BlocProvider.value(
          value: taskBloc,
          child: TaskCreateDialog(
            projectId: widget.project.id,
            onCreated: () {
              context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
            },
          ),
        );
        
        if (projectBloc != null) {
          dialog = BlocProvider.value(
            value: projectBloc,
            child: dialog,
          );
        }
        
        return dialog;
      },
    );
  }

  Widget _buildView(TaskState state) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.project.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _columnsLoading ? null : _showCreateColumnDialog,
                  icon: const Icon(Icons.add_card),
                  label: const Text('Добавить колонку'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать задачу'),
                ),
              ],
            ),
          ),
        if (!isMobile) const Divider(height: 1),
        Expanded(
          child: state.isLoading && state.tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Board(
              tasks: state.tasks,
              columns: _columns ?? const [],
              onTaskTap: (task) {
                TaskDetailDialog.show(context, task);
              },
              onTaskColumnIdChanged: (task, newColumnId) {
                context.read<TaskBloc>().add(
                  TaskColumnIdEditRequested(
                    taskId: task.id,
                    columnId: newColumnId,
                  ),
                );
              },
              onColumnEdit: _showEditColumnDialog,
            ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<TaskBloc>().add(const TaskClearError());
        }
      },
      builder: (context, state) {
        return _buildView(state);
      },
    );
  }
}
