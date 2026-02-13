import 'package:flutter/material.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/presentation/screens/tasks/widgets/task_detail_view.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;

  const TaskDetailDialog({super.key, required this.task});

  static void show(BuildContext context, Task task) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 600.0;
    final maxHeight = isMobile ? double.infinity : 700.0;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: TaskDetailDialog(task: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.dialogBackgroundColor,
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
                task: task,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
