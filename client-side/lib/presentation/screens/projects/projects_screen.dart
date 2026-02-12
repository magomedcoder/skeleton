import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/screens/projects/bloc/project_state.dart';
import 'package:legion/presentation/screens/projects/project_add_members_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(const ProjectsStarted());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    _nameController.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый проект'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => _submitCreate(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => _submitCreate(ctx),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _submitCreate(BuildContext dialogContext) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(dialogContext).pop();
    context.read<ProjectBloc>().add(ProjectCreateRequested(name));
  }

  Future<void> _openAddMembers(Project project) async {
    final bloc = context.read<ProjectBloc>();
    final state = bloc.state;
    final existingIds = state.selectedProject?.id == project.id
      ? state.members.map((u) => int.tryParse(u.id)).whereType<int>().toList()
      : <int>[];

    final result = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute<List<int>>(
        builder: (_) => ProjectAddMembersScreen(
          projectId: project.id,
          existingMemberIds: existingIds,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      context.read<ProjectBloc>().add(
        ProjectAddMembersRequested(project.id, result),
      );
    }
  }

  Widget _buildProjectList(ProjectState state) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.projects.isEmpty) {
      return const Center(
        child: Text(
          'Проектов пока нет.\nСоздайте первый проект.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: state.projects.length,
      itemBuilder: (context, index) {
        final project = state.projects[index];
        final isSelected = project.id == state.selectedProject?.id;
        return ListTile(
          selected: isSelected,
          title: Text(project.name),
          onTap: () {
            context.read<ProjectBloc>().add(ProjectSelected(project));
          },
        );
      },
    );
  }

  Widget _buildDetail(ProjectState state) {
    final project = state.selectedProject;
    if (project == null) {
      return const Center(child: Text('Выберите проект'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Добавить участников',
                onPressed: () => _openAddMembers(project),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (state.isMembersLoading && state.members.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.members.isEmpty)
          const Expanded(child: Center(child: Text('Участников пока нет')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: state.members.length,
              itemBuilder: (context, index) {
                final user = state.members[index];
                return _MemberTile(user: user);
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ProjectBloc>().add(const ProjectClearError());
        }
      },
      builder: (context, state) {
        final isMobile = Breakpoints.isMobile(context);
        final body = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile)
              SizedBox(width: 260, child: _buildProjectList(state)),
            Expanded(child: _buildDetail(state)),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            leading: isMobile && state.selectedProject != null
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.read<ProjectBloc>().add(
                    const ProjectClearSelection(),
                  );
                },
              )
              : null,
            title: const Text('Проекты'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Новый проект',
                onPressed: () => _showCreateDialog(context),
              ),
            ],
          ),
          body: isMobile
            ? state.selectedProject == null
              ? _buildProjectList(state)
              : _buildDetail(state)
            : body,
          drawer: isMobile && state.selectedProject == null
            ? Drawer(child: SafeArea(child: _buildProjectList(state)))
            : null,
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User user;

  const _MemberTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
      ),
      title: Text(user.username),
      subtitle: Text('${user.name} ${user.surname}'),
    );
  }
}
