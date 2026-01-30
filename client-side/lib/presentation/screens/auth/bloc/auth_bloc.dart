import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/data/data_sources/local/auth_local_data_source.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_event.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthLocalDataSourceImpl tokenStorage;
  final GrpcChannelManager channelManager;

  AuthBloc({
    required this.loginUseCase,
    required this.refreshTokenUseCase,
    required this.logoutUseCase,
    required this.tokenStorage,
    required this.channelManager,
  }) : super(const AuthState()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRefreshTokenRequested>(_onRefreshTokenRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthClearError>(_onClearError);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
      return;
    }

    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 1500);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final tokens = await refreshTokenUseCase(refreshToken);
        tokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
        final user = tokenStorage.user;

        if (user == null) {
          tokenStorage.clearTokens();
          emit(
            state.copyWith(
              isLoading: false,
              isAuthenticated: false,
              user: null,
              error: null,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
            error: null,
          ),
        );
        return;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('Недействительный refresh token')) {
          break;
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay);
        }
      }
    }

    tokenStorage.clearTokens();
    emit(
      state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: null,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await channelManager.setServer(event.host, event.port);
      final result = await loginUseCase(event.username, event.password);

      tokenStorage.saveTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
      tokenStorage.saveUser(result.user);

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
    } catch (_) {

    } finally {
      tokenStorage.clearTokens();
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
    }
  }

  void _onClearError(AuthClearError event, Emitter<AuthState> emit) {
    emit(state.copyWith(error: null));
  }
}
