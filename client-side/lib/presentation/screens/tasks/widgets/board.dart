import 'package:flutter/material.dart';
import 'package:legion/core/date_formatter.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/domain/entities/task.dart';

class Board extends StatelessWidget {
  final List<Task> tasks;
  final List<BoardColumn> columns;
  final Function(Task) onTaskTap;
  final Function(Task, String)? onTaskColumnIdChanged;
  final Function(BoardColumn)? onColumnEdit;

  const Board({
    super.key,
    required this.tasks,
    required this.columns,
    required this.onTaskTap,
    this.onTaskColumnIdChanged,
    this.onColumnEdit,
  });

  static Color _colorFromHex(String hex) {
    if (hex.isEmpty) {
      return Colors.grey;
    }

    var h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) {
      h = 'FF$h';
    }

    final v = int.tryParse(h, radix: 16);
    if (v == null) {
      return Colors.grey;
    }

    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 8.0 : 16.0;
    final columnSpacing = isMobile ? 12.0 : 16.0;
    final columnWidth = isMobile ? 280.0 : null;

    if (columns.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_column_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Нет колонок',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте колонку для начала работы',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final columnWidgets = columns.map((col) {
      final columnTasks = tasks.where((t) => t.columnId == col.id).toList();
      return _Column(
        column: col,
        color: _colorFromHex(col.color),
        tasks: columnTasks,
        onTaskTap: onTaskTap,
        onTaskColumnIdChanged: onTaskColumnIdChanged,
        onColumnEdit: onColumnEdit,
      );
    }).toList();

    if (isMobile) {
      return Container(
        padding: EdgeInsets.all(padding),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: columnWidgets.length,
          itemBuilder: (context, index) {
            return Container(
              width: columnWidth,
              margin: EdgeInsets.only(
                right: index < columnWidgets.length - 1 ? columnSpacing : 0,
              ),
              child: columnWidgets[index],
            );
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnWidgets.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < columnWidgets.length - 1 ? columnSpacing : 0,
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
  final BoardColumn column;
  final Color color;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, String)? onTaskColumnIdChanged;
  final Function(BoardColumn)? onColumnEdit;

  const _Column({
    required this.column,
    required this.color,
    required this.tasks,
    required this.onTaskTap,
    this.onTaskColumnIdChanged,
    this.onColumnEdit,
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
                  column.title,
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
              if (onColumnEdit != null && column.id.isNotEmpty) ...[
                SizedBox(width: spacing),
                IconButton(
                  icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                  color: color,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Редактировать колонку',
                  onPressed: () => onColumnEdit!(column),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: DragTarget<Task>(
            onAcceptWithDetails: (details) {
              final task = details.data;
              if (onTaskColumnIdChanged != null && task.columnId != column.id) {
                onTaskColumnIdChanged!(task, column.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isDraggingOver = candidateData.isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: isDraggingOver
                      ? color.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Нет задач',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
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

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 13 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Card(
          margin: EdgeInsets.only(bottom: margin),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Text(
              task.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ),
      ),
      child: Card(
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
                      DateFormatter.formatRelativeDate(task.createdAt),
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
      ),
    );
  }

}
