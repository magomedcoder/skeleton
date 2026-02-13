import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_event.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_state.dart';
import 'package:legion/presentation/screens/tasks/widgets/board.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_create_dialog.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_detail_dialog.dart';

class TasksScreen extends StatefulWidget {
  final Project project;

  const TasksScreen({super.key, required this.project});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
    });
  }

  void _showCreateDialog(BuildContext context) {
    final taskBloc = context.read<TaskBloc>();
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: taskBloc,
        child: TaskCreateDialog(
          projectId: widget.project.id,
          onCreated: () {
            context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
          },
        ),
      ),
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
              onTaskTap: (task) {
                TaskDetailDialog.show(context, task);
              },
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
