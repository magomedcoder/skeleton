import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/domain/usecases/project/add_user_to_project_usecase.dart';
import 'package:legion/domain/usecases/project/create_project_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_members_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_usecase.dart';
import 'package:legion/domain/usecases/project/get_projects_usecase.dart';
import 'package:legion/presentation/screens/projects/bloc/project_event.dart';
import 'package:legion/presentation/screens/projects/bloc/project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjectsUseCase getProjectsUseCase;
  final CreateProjectUseCase createProjectUseCase;
  final GetProjectUseCase getProjectUseCase;
  final GetProjectMembersUseCase getProjectMembersUseCase;
  final AddUserToProjectUseCase addUserToProjectUseCase;

  ProjectBloc({
    required this.getProjectsUseCase,
    required this.createProjectUseCase,
    required this.getProjectUseCase,
    required this.getProjectMembersUseCase,
    required this.addUserToProjectUseCase,
  }) : super(const ProjectState()) {
    on<ProjectsStarted>(_onStarted);
    on<ProjectCreateRequested>(_onCreateRequested);
    on<ProjectSelected>(_onSelected);
    on<ProjectMembersLoadRequested>(_onMembersLoadRequested);
    on<ProjectAddMembersRequested>(_onAddMembersRequested);
    on<ProjectClearSelection>(_onClearSelection);
    on<ProjectClearError>(_onClearError);
  }

  Future<void> _onStarted(
    ProjectsStarted event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final projects = await getProjectsUseCase();
      emit(state.copyWith(isLoading: false, projects: projects));
    } catch (e) {
      Logs().e('ProjectBloc: ошибка загрузки проектов', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка загрузки проектов'));
    }
  }

  Future<void> _onCreateRequested(
    ProjectCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final project = await createProjectUseCase(name);
      final projects = [...state.projects, project];
      emit(
        state.copyWith(
          isLoading: false,
          projects: projects,
          selectedProject: project,
          members: const [],
        ),
      );
      add(ProjectMembersLoadRequested(project.id));
    } catch (e) {
      Logs().e('ProjectBloc: ошибка создания проекта', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка создания проекта'));
    }
  }

  Future<void> _onSelected(
    ProjectSelected event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedProject: event.project,
        members: const [],
        isMembersLoading: true,
        error: null,
      ),
    );
    add(ProjectMembersLoadRequested(event.project.id));
  }

  Future<void> _onMembersLoadRequested(
    ProjectMembersLoadRequested event,
    Emitter<ProjectState> emit,
  ) async {
    if (state.selectedProject?.id != event.projectId) return;

    emit(state.copyWith(isMembersLoading: true, error: null));
    try {
      final members = await getProjectMembersUseCase(event.projectId);
      emit(state.copyWith(members: members, isMembersLoading: false));
    } catch (e) {
      Logs().e('ProjectBloc: ошибка загрузки участников', e);
      emit(
        state.copyWith(
          isMembersLoading: false,
          error: 'Ошибка загрузки участников',
        ),
      );
    }
  }

  Future<void> _onAddMembersRequested(
    ProjectAddMembersRequested event,
    Emitter<ProjectState> emit,
  ) async {
    if (event.userIds.isEmpty) return;

    emit(state.copyWith(isMembersLoading: true, error: null));
    try {
      await addUserToProjectUseCase(event.projectId, event.userIds);
      add(ProjectMembersLoadRequested(event.projectId));
    } catch (e) {
      Logs().e('ProjectBloc: ошибка добавления участников', e);
      emit(
        state.copyWith(
          isMembersLoading: false,
          error: 'Ошибка добавления участников',
        ),
      );
    }
  }

  void _onClearSelection(
    ProjectClearSelection event,
    Emitter<ProjectState> emit,
  ) {
    emit(state.copyWith(clearSelectedProject: true, members: const []));
  }

  void _onClearError(ProjectClearError event, Emitter<ProjectState> emit) {
    emit(state.copyWith(error: null));
  }
}
