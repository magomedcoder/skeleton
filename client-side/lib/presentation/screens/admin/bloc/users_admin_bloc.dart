import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/domain/usecases/users/create_user_usecase.dart';
import 'package:legion/domain/usecases/users/get_users_usecase.dart';
import 'package:legion/domain/usecases/users/edit_user_usecase.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_event.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_state.dart';

class UsersAdminBloc extends Bloc<UsersAdminEvent, UsersAdminState> {
  final GetUsersUseCase getUsersUseCase;
  final CreateUserUseCase createUserUseCase;
  final EditUserUseCase editUserUseCase;

  UsersAdminBloc({
    required this.getUsersUseCase,
    required this.createUserUseCase,
    required this.editUserUseCase,
  }) : super(const UsersAdminState()) {
    on<UsersAdminLoadRequested>(_onLoad);
    on<UsersAdminCreateRequested>(_onCreate);
    on<UsersAdminUpdateRequested>(_onUpdate);
    on<UsersAdminClearError>(_onClearError);
  }

  Future<void> _onLoad(
    UsersAdminLoadRequested event,
    Emitter<UsersAdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final users = await getUsersUseCase(
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(state.copyWith(isLoading: false, users: users, error: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreate(
    UsersAdminCreateRequested event,
    Emitter<UsersAdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await createUserUseCase(
        username: event.username,
        password: event.password,
        name: event.name,
        surname: event.surname,
        role: event.role,
      );
      final users = await getUsersUseCase(page: 1, pageSize: 50);
      emit(state.copyWith(isLoading: false, users: users, error: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    UsersAdminUpdateRequested event,
    Emitter<UsersAdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await editUserUseCase(
        id: event.id,
        username: event.username,
        password: event.password,
        name: event.name,
        surname: event.surname,
        role: event.role,
      );
      final users = await getUsersUseCase(page: 1, pageSize: 50);
      emit(state.copyWith(isLoading: false, users: users, error: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onClearError(
    UsersAdminClearError event,
    Emitter<UsersAdminState> emit,
  ) {
    emit(state.copyWith(error: null));
  }
}
