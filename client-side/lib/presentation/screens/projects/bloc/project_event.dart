import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class ProjectsStarted extends ProjectEvent {
  const ProjectsStarted();
}

class ProjectCreateRequested extends ProjectEvent {
  final String name;

  const ProjectCreateRequested(this.name);

  @override
  List<Object?> get props => [name];
}

class ProjectSelected extends ProjectEvent {
  final Project project;

  const ProjectSelected(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectMembersLoadRequested extends ProjectEvent {
  final String projectId;

  const ProjectMembersLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ProjectAddMembersRequested extends ProjectEvent {
  final String projectId;
  final List<int> userIds;

  const ProjectAddMembersRequested(this.projectId, this.userIds);

  @override
  List<Object?> get props => [projectId, userIds];
}

class ProjectClearSelection extends ProjectEvent {
  const ProjectClearSelection();
}

class ProjectClearError extends ProjectEvent {
  const ProjectClearError();
}
