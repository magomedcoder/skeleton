import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/screens/projects/bloc/project_state.dart';
import 'package:legion/presentation/screens/projects/project_add_members_screen.dart';

class ProjectMembersScreen extends StatefulWidget {
  final Project project;

  const ProjectMembersScreen({super.key, required this.project});

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(ProjectSelected(widget.project));
      context.read<ProjectBloc>().add(
        ProjectMembersLoadRequested(widget.project.id),
      );
    });
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
      context.read<ProjectBloc>().add(ProjectMembersLoadRequested(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Участники: ${widget.project.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Добавить участников',
                onPressed: () => _openAddMembers(widget.project),
              ),
            ],
          ),
          body: _buildMembersList(state),
        );
      },
    );
  }

  Widget _buildMembersList(ProjectState state) {
    if (state.isMembersLoading && state.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Участников пока нет',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _openAddMembers(widget.project),
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить участников'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: state.members.length,
      itemBuilder: (context, index) {
        final user = state.members[index];
        return _MemberTile(user: user);
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
