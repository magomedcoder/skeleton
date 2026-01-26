import 'package:legion/core/token_storage.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_event.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final TokenStorage tokenStorage;

  AuthBloc({
    required this.loginUseCase,
    required this.refreshTokenUseCase,
    required this.logoutUseCase,
    required this.tokenStorage,
  }) : super(const AuthState()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRefreshTokenRequested>(_onRefreshTokenRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthClearError>(_onClearError);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await loginUseCase(event.username, event.password);

      tokenStorage.saveTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );

      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRefreshTokenRequested(
    AuthRefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final tokens = await refreshTokenUseCase(event.refreshToken);

      tokenStorage.saveTokens(
        tokens.accessToken,
        tokens.refreshToken,
      );

      emit(state.copyWith(isLoading: false, error: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await logoutUseCase();

      tokenStorage.clearTokens();

      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onClearError(AuthClearError event, Emitter<AuthState> emit) {
    emit(state.copyWith(error: null));
  }
}
