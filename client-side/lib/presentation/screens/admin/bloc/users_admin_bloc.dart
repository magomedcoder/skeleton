import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/domain/usecases/users/create_user_usecase.dart';
import 'package:skeleton/domain/usecases/users/get_users_usecase.dart';
import 'package:skeleton/domain/usecases/users/edit_user_usecase.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_event.dart';
import 'package:skeleton/presentation/screens/admin/bloc/users_admin_state.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/utils/request_logout_on_unauthorized.dart';

class UsersAdminBloc extends Bloc<UsersAdminEvent, UsersAdminState> {
  final AuthBloc authBloc;
  final GetUsersUseCase getUsersUseCase;
  final CreateUserUseCase createUserUseCase;
  final EditUserUseCase editUserUseCase;

  UsersAdminBloc({
    required this.authBloc,
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
    Logs().d('UsersAdminBloc: загрузка пользователей page=${event.page}');
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final users = await getUsersUseCase(
        page: event.page,
        pageSize: event.pageSize,
      );
      Logs().i('UsersAdminBloc: загружено пользователей: ${users.length}');
      emit(state.copyWith(
        isLoading: false,
        users: users,
        error: null,
        currentPage: event.page,
        pageSize: event.pageSize,
      ));
    } catch (e) {
      Logs().e('UsersAdminBloc: ошибка загрузки пользователей', e);
      requestLogoutIfUnauthorized(e, authBloc);
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
    Logs().i('UsersAdminBloc: создание пользователя ${event.username}');
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await createUserUseCase(
        username: event.username,
        password: event.password,
        name: event.name,
        surname: event.surname,
        role: event.role,
      );

      Logs().i('UsersAdminBloc: пользователь создан');
      add(UsersAdminLoadRequested(
        page: state.currentPage,
        pageSize:
        state.pageSize,
      ));
    } catch (e) {
      Logs().e('UsersAdminBloc: ошибка создания пользователя', e);
      requestLogoutIfUnauthorized(e, authBloc);
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
    Logs().d('UsersAdminBloc: обновление пользователя ${event.id}');
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

      Logs().i('UsersAdminBloc: пользователь обновлён');
      add(UsersAdminLoadRequested(
        page: state.currentPage,
        pageSize: state.pageSize,
      ));
    } catch (e) {
      Logs().e('UsersAdminBloc: ошибка обновления пользователя', e);
      requestLogoutIfUnauthorized(e, authBloc);
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
