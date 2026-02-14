import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/project_history_view.dart';
import 'package:legion/presentation/screens/projects/project_members_screen.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:legion/presentation/screens/tasks/tasks_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  void _openMembers() {
    final projectBloc = context.read<ProjectBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: projectBloc,
          child: ProjectMembersScreen(project: widget.project),
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectHistoryView(projectId: widget.project.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TaskBloc>(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.project.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'История',
              onPressed: _openHistory,
            ),
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Участники проекта',
              onPressed: _openMembers,
            ),
          ],
        ),
        body: Builder(
          builder: (context) => BlocProvider.value(
            value: context.read<TaskBloc>(),
            child: TasksScreen(project: widget.project),
          ),
        ),
      ),
    );
  }
}
