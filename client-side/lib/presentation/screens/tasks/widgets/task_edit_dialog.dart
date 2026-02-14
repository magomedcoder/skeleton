import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/task.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/screens/projects/bloc/project_state.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_event.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_state.dart';

class TaskEditDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onSaved;

  const TaskEditDialog({super.key, required this.task, this.onSaved});

  static Future<Task?> show(
    BuildContext context,
    Task task, {
    VoidCallback? onSaved,
    TaskBloc? taskBloc,
    ProjectBloc? projectBloc,
  }) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 700.0;
    final maxHeight = isMobile ? double.infinity : 600.0;

    return showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Widget content = TaskEditDialog(task: task, onSaved: onSaved);
        if (projectBloc != null) {
          content = BlocProvider<ProjectBloc>.value(
            value: projectBloc,
            child: content,
          );
        }
        if (taskBloc != null) {
          content = BlocProvider<TaskBloc>.value(
            value: taskBloc,
            child: content,
          );
        }
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: content,
          ),
        );
      },
    );
  }

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  int? _selectedAssignerId;
  int? _selectedExecutorId;
  List<User> _members = [];
  bool _waitingForResult = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedAssignerId = widget.task.assigner;
    _selectedExecutorId = widget.task.executor;
    _loadMembers();
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.task.projectId));

      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members;
            if (_selectedAssignerId != null && !_members.any((u) => int.tryParse(u.id) == _selectedAssignerId)) {

              if (_members.isNotEmpty) {
                _selectedAssignerId = int.tryParse(_members.first.id);
              }
            }
            if (_selectedExecutorId != null && !_members.any((u) => int.tryParse(u.id) == _selectedExecutorId)) {

              if (_members.isNotEmpty) {
                _selectedExecutorId = int.tryParse(_members.first.id);
              }
            }
          });
        }
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssignerId == null || _selectedExecutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите постановщика и исполнителя'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
      _waitingForResult = true;
    });

    context.read<TaskBloc>().add(
      TaskEditRequested(
        taskId: widget.task.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        assigner: _selectedAssignerId!,
        executor: _selectedExecutorId!,
      ),
    );
  }

  String _getUserDisplayName(User user) {
    final name = '${user.name} ${user.surname}'.trim();
    return name.isNotEmpty ? name : '@${user.username}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (!_waitingForResult) return;
        if (state.error != null && _isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isSubmitting = false;
            _waitingForResult = false;
          });
        } else if (!state.isLoading && _isSubmitting && state.error == null) {
          Task? updated;
          try {
            updated = state.tasks.firstWhere((t) => t.id == widget.task.id);
          } catch (_) {}

          if (updated != null) {
            widget.onSaved?.call();
            Navigator.of(context).pop(updated);
          }

          setState(() {
            _isSubmitting = false;
            _waitingForResult = false;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Редактировать задачу',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название задачи',
                        border: OutlineInputBorder(),
                        hintText: 'Введите название задачи',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Название обязательно';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Описание',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Добавьте описание задачи',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Постановщик',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProjectBloc, ProjectState>(
                      builder: (context, projectState) {
                        if (projectState.isMembersLoading && _members.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedAssignerId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _members.map((user) {
                            final userId = int.tryParse(user.id);
                            if (userId == null) return null;
                            return DropdownMenuItem<int>(
                              value: userId,
                              child: Text(_getUserDisplayName(user)),
                            );
                          })
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                          onChanged: _isSubmitting
                            ? null
                            : (value) {
                              setState(() => _selectedAssignerId = value);
                            },
                          validator: (value) {
                            if (value == null) return 'Выберите постановщика';
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Исполнитель',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProjectBloc, ProjectState>(
                      builder: (context, projectState) {
                        if (projectState.isMembersLoading && _members.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedExecutorId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _members.map((user) {
                            final userId = int.tryParse(user.id);
                            if (userId == null) return null;
                            return DropdownMenuItem<int>(
                              value: userId,
                              child: Text(_getUserDisplayName(user)),
                            );
                          })
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                          onChanged: _isSubmitting
                            ? null
                            : (value) {
                              setState(() => _selectedExecutorId = value);
                            },
                          validator: (value) {
                            if (value == null) return 'Выберите исполнителя';
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
