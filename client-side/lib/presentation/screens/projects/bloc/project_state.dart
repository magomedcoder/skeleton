import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/project.dart';
import 'package:legion/domain/entities/user.dart';

class ProjectState extends Equatable {
  final bool isLoading;
  final List<Project> projects;
  final Project? selectedProject;
  final List<User> members;
  final bool isMembersLoading;
  final String? error;

  const ProjectState({
    this.isLoading = false,
    this.projects = const [],
    this.selectedProject,
    this.members = const [],
    this.isMembersLoading = false,
    this.error,
  });

  ProjectState copyWith({
    bool? isLoading,
    List<Project>? projects,
    Project? selectedProject,
    bool clearSelectedProject = false,
    List<User>? members,
    bool? isMembersLoading,
    String? error,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      selectedProject: clearSelectedProject
        ? null
        : (selectedProject ?? this.selectedProject),
      members: members ?? this.members,
      isMembersLoading: isMembersLoading ?? this.isMembersLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    projects,
    selectedProject,
    members,
    isMembersLoading,
    error,
  ];
}
