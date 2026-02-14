import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/screens/projects/bloc/project_state.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_event.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_state.dart';
import 'package:legion/presentation/widgets/markdown_editor.dart';

class TaskCreateDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback? onCreated;

  const TaskCreateDialog({super.key, required this.projectId, this.onCreated});

  @override
  State<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<TaskCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  int? _selectedExecutorId;
  List<User> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.projectId));
      
      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members;
            if (_selectedExecutorId == null) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId = authState.user?.id;
              if (currentUserId != null) {
                final currentUser = _members.firstWhere(
                  (u) => u.id == currentUserId,
                  orElse: () => _members.first,
                );
                _selectedExecutorId = int.tryParse(currentUser.id) ?? int.tryParse(_members.first.id);
              } else if (_members.isNotEmpty) {
                _selectedExecutorId = int.tryParse(_members.first.id);
              }
            }
          });
        }
      });
    } catch (e) {
      Logs().d('TaskCreateDialog: _loadMembers', e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExecutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите ответственного'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<TaskBloc>().add(
      TaskCreateRequested(
        projectId: widget.projectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        executor: _selectedExecutorId!,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pop();
      widget.onCreated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 700.0;
    final maxHeight = isMobile ? double.infinity : 600.0;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.error != null && _isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isSubmitting = false);
        } else if (!state.isLoading && _isSubmitting && state.error == null) {
          Navigator.of(context).pop();
          widget.onCreated?.call();
          setState(() => _isSubmitting = false);
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        'Создать задачу',
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
                          autofocus: true,
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
                        MarkdownEditor(
                          controller: _descriptionController,
                          hintText: 'Добавьте описание задачи (поддерживается Markdown)',
                          minLines: 6,
                          maxLines: 12,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ответственный',
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
                                  child: Text(user.displayName),
                                );
                              }).whereType<DropdownMenuItem<int>>().toList(),
                              onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedExecutorId = value;
                                    });
                                  },
                              validator: (value) {
                                if (value == null) {
                                  return 'Выберите ответственного';
                                }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                        : const Text('Создать'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
