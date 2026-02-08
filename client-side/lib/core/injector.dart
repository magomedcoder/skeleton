import 'package:get_it/get_it.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/server_config.dart';
import 'package:legion/data/data_sources/local/session_model_local_data_source.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/ai_chat_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/editor_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/runners_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/user_remote_datasource.dart';
import 'package:legion/data/repositories/auth_repository_impl.dart';
import 'package:legion/data/repositories/ai_chat_repository_impl.dart';
import 'package:legion/data/repositories/editor_repository_impl.dart';
import 'package:legion/data/repositories/runners_repository_impl.dart';
import 'package:legion/data/repositories/user_repository_impl.dart';
import 'package:legion/domain/repositories/auth_repository.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';
import 'package:legion/domain/repositories/editor_repository.dart';
import 'package:legion/domain/repositories/runners_repository.dart';
import 'package:legion/domain/repositories/user_repository.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/change_password_usecase.dart';
import 'package:legion/domain/usecases/auth/get_devices_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/domain/usecases/auth/revoke_device_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/connect_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/create_session_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/delete_session_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/get_models_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/get_session_messages_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/get_session_model_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/get_sessions_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/send_message_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/set_session_model_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/update_session_model_usecase.dart';
import 'package:legion/domain/usecases/ai_chat/update_session_title_usecase.dart';
import 'package:legion/domain/usecases/editor/transform_text_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_status_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_usecase.dart';
import 'package:legion/domain/usecases/runners/set_runner_enabled_usecase.dart';
import 'package:legion/domain/usecases/users/create_user_usecase.dart';
import 'package:legion/domain/usecases/users/get_users_usecase.dart';
import 'package:legion/domain/usecases/users/edit_user_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_bloc.dart';
import 'package:legion/presentation/cubit/theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<UserLocalDataSourceImpl>(() => UserLocalDataSourceImpl());
  await sl<UserLocalDataSourceImpl>().init();

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  await sl<ServerConfig>().init();

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<UserLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<AuthGuard>(
    () => AuthGuard(
      () async {
        final storage = sl<UserLocalDataSourceImpl>();
        final refreshToken = storage.refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) return false;
        try {
          final tokens = await sl<RefreshTokenUseCase>()(refreshToken);
          storage.saveTokens(tokens.accessToken, tokens.refreshToken);
          return true;
        } catch (_) {
          return false;
        }
      },
    ),
  );

  sl.registerLazySingleton<GrpcChannelManager>(
    () => GrpcChannelManager(sl<ServerConfig>(), sl<AuthInterceptor>()),
  );

  sl.registerLazySingleton<IAIChatRemoteDataSource>(
    () => AIChatRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IEditorRemoteDataSource>(
    () => EditorRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<SessionModelLocalDataSource>(
    () => SessionModelLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<GrpcChannelManager>(), sl<UserLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<IUserRemoteDataSource>(
    () => UserRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IRunnersRemoteDataSource>(
    () => RunnersRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<AIChatRepository>(
    () => AIChatRepositoryImpl(sl(), sl<SessionModelLocalDataSource>()),
  );
  sl.registerLazySingleton<EditorRepository>(() => EditorRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<RunnersRepository>(
    () => RunnersRepositoryImpl(sl<IRunnersRemoteDataSource>()),
  );

  sl.registerFactory(() => GetRunnersUseCase(sl()));
  sl.registerFactory(() => SetRunnerEnabledUseCase(sl()));
  sl.registerFactory(() => GetRunnersStatusUseCase(sl()));

  sl.registerFactory(() => ConnectUseCase(sl()));
  sl.registerFactory(() => GetModelsUseCase(sl()));
  sl.registerFactory(() => SendMessageUseCase(sl()));
  sl.registerFactory(() => CreateSessionUseCase(sl()));
  sl.registerFactory(() => GetSessionsUseCase(sl()));
  sl.registerFactory(() => GetSessionMessagesUseCase(sl()));
  sl.registerFactory(() => GetSessionModelUseCase(sl()));
  sl.registerFactory(() => SetSessionModelUseCase(sl()));
  sl.registerFactory(() => UpdateSessionModelUseCase(sl()));
  sl.registerFactory(() => DeleteSessionUseCase(sl()));
  sl.registerFactory(() => UpdateSessionTitleUseCase(sl()));
  sl.registerFactory(() => TransformTextUseCase(sl()));

  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => ChangePasswordUseCase(sl(), sl<UserLocalDataSourceImpl>()));
  sl.registerFactory(() => GetDevicesUseCase(sl()));
  sl.registerFactory(() => RevokeDeviceUseCase(sl()));

  sl.registerFactory(() => GetUsersUseCase(sl()));
  sl.registerFactory(() => CreateUserUseCase(sl()));
  sl.registerFactory(() => EditUserUseCase(sl()));

  sl.registerFactory(
    () => AIChatBloc(
      authBloc: sl<AuthBloc>(),
      connectUseCase: sl(),
      getModelsUseCase: sl(),
      getSessionModelUseCase: sl(),
      setSessionModelUseCase: sl(),
      updateSessionModelUseCase: sl(),
      sendMessageUseCase: sl(),
      createSessionUseCase: sl(),
      getSessionsUseCase: sl(),
      getSessionMessagesUseCase: sl(),
      deleteSessionUseCase: sl(),
      updateSessionTitleUseCase: sl(),
      getRunnersStatusUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => EditorBloc(
      authBloc: sl<AuthBloc>(),
      getModelsUseCase: sl(),
      transformTextUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      refreshTokenUseCase: sl(),
      logoutUseCase: sl(),
      tokenStorage: sl<UserLocalDataSourceImpl>(),
      channelManager: sl(),
      authGuard: sl<AuthGuard>(),
    ),
  );

  sl.registerFactory(
    () => UsersAdminBloc(
      authBloc: sl<AuthBloc>(),
      getUsersUseCase: sl(),
      createUserUseCase: sl(),
      editUserUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => RunnersAdminBloc(
      getRunnersUseCase: sl(),
      setRunnerEnabledUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => DevicesBloc(
      getDevicesUseCase: sl(),
      revokeDeviceUseCase: sl(),
    ),
  );

  sl.registerFactory(() => ThemeCubit(sl<UserLocalDataSourceImpl>()));
}
