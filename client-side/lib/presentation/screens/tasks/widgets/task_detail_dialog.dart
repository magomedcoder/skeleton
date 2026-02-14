import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_detail_view.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_edit_dialog.dart';

class TaskDetailDialog extends StatefulWidget {
  final Task task;

  const TaskDetailDialog({super.key, required this.task});

  static void show(BuildContext context, Task task) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 600.0;
    final maxHeight = isMobile ? double.infinity : 700.0;

    ProjectBloc? projectBloc;
    TaskBloc? taskBloc;
    try {
      projectBloc = context.read<ProjectBloc>();
    } catch (e) {}
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (e) {}

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Widget dialogContent = TaskDetailDialog(task: task);
        if (projectBloc != null) {
          dialogContent = BlocProvider<ProjectBloc>.value(
            value: projectBloc,
            child: dialogContent,
          );
        }
        if (taskBloc != null) {
          dialogContent = BlocProvider<TaskBloc>.value(
            value: taskBloc,
            child: dialogContent,
          );
        }

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: dialogContent,
          ),
        );
      },
    );
  }

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _openEdit() async {
    final taskBloc = context.read<TaskBloc>();
    final projectBloc = context.read<ProjectBloc>();
    final updated = await TaskEditDialog.show(
      context,
      _task,
      taskBloc: taskBloc,
      projectBloc: projectBloc,
    );
    if (updated != null && mounted) {
      setState(() => _task = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(isMobile ? 0 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Детали задачи',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _openEdit,
                  tooltip: 'Редактировать',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: TaskDetailView(
                task: _task,
                projectId: _task.projectId,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
