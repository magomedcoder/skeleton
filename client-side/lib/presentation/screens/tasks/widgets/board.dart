import 'package:flutter/material.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/task.dart';

class Board extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const Board({super.key, required this.tasks, required this.onTaskTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 8.0 : 16.0;
    final columnSpacing = isMobile ? 12.0 : 16.0;
    final columnWidth = isMobile ? 280.0 : null;

    final columns = [
      _Column(
        title: 'Задачи',
        color: Colors.grey,
        tasks: tasks,
        onTaskTap: onTaskTap,
      ),
    ];

    if (isMobile) {
      return Container(
        padding: EdgeInsets.all(padding),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: columns.length,
          itemBuilder: (context, index) {
            return Container(
              width: columnWidth,
              margin: EdgeInsets.only(
                right: index < columns.length - 1 ? columnSpacing : 0,
              ),
              child: columns[index],
            );
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < columns.length - 1 ? columnSpacing : 0,
              ),
              child: column,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const _Column({
    required this.title,
    required this.color,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 10.0 : 12.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: isMobile ? 16 : 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: spacing),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: tasks.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Нет задач',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _Card(
                  task: task,
                  onTap: () => onTaskTap(task),
                );
              },
            ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _Card({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 10.0 : 12.0;
    final margin = isMobile ? 6.0 : 8.0;

    return Card(
      margin: EdgeInsets.only(bottom: margin),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                ),
                maxLines: isMobile ? 2 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.description.isNotEmpty) ...[
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isMobile ? 11 : null,
                  ),
                  maxLines: isMobile ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: isMobile ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: isMobile ? 3 : 4),
                  Text(
                    _formatDate(task.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 11 : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
