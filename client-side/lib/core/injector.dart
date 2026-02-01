import 'package:get_it/get_it.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/server_config.dart';
import 'package:legion/data/data_sources/local/auth_local_data_source.dart';
import 'package:legion/data/data_sources/local/session_model_local_data_source.dart';
import 'package:legion/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/runners_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/user_remote_datasource.dart';
import 'package:legion/data/repositories/auth_repository_impl.dart';
import 'package:legion/data/repositories/chat_repository_impl.dart';
import 'package:legion/data/repositories/runners_repository_impl.dart';
import 'package:legion/data/repositories/user_repository_impl.dart';
import 'package:legion/domain/repositories/auth_repository.dart';
import 'package:legion/domain/repositories/chat_repository.dart';
import 'package:legion/domain/repositories/runners_repository.dart';
import 'package:legion/domain/repositories/user_repository.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/change_password_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/domain/usecases/chat/connect_usecase.dart';
import 'package:legion/domain/usecases/chat/create_session_usecase.dart';
import 'package:legion/domain/usecases/chat/delete_session_usecase.dart';
import 'package:legion/domain/usecases/chat/get_models_usecase.dart';
import 'package:legion/domain/usecases/chat/get_session_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/get_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/get_sessions_usecase.dart';
import 'package:legion/domain/usecases/chat/send_message_usecase.dart';
import 'package:legion/domain/usecases/chat/set_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/update_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/update_session_title_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_status_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_usecase.dart';
import 'package:legion/domain/usecases/runners/set_runner_enabled_usecase.dart';
import 'package:legion/domain/usecases/users/create_user_usecase.dart';
import 'package:legion/domain/usecases/users/get_users_usecase.dart';
import 'package:legion/domain/usecases/users/edit_user_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AuthLocalDataSourceImpl>(() => AuthLocalDataSourceImpl());
  await sl<AuthLocalDataSourceImpl>().init();

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  await sl<ServerConfig>().init();

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<AuthLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<GrpcChannelManager>(
    () => GrpcChannelManager(sl<ServerConfig>(), sl<AuthInterceptor>()),
  );

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl<GrpcChannelManager>()),
  );

  sl.registerLazySingleton<SessionModelLocalDataSource>(
    () => SessionModelLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<GrpcChannelManager>()),
  );

  sl.registerLazySingleton<IUserRemoteDataSource>(
    () => UserRemoteDataSource(sl<GrpcChannelManager>()),
  );

  sl.registerLazySingleton<IRunnersRemoteDataSource>(
    () => RunnersRemoteDataSource(sl<GrpcChannelManager>()),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl(), sl<SessionModelLocalDataSource>()),
  );
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

  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => ChangePasswordUseCase(sl()));

  sl.registerFactory(() => GetUsersUseCase(sl()));
  sl.registerFactory(() => CreateUserUseCase(sl()));
  sl.registerFactory(() => EditUserUseCase(sl()));

  sl.registerFactory(
    () => ChatBloc(
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
    () => AuthBloc(
      loginUseCase: sl(),
      refreshTokenUseCase: sl(),
      logoutUseCase: sl(),
      tokenStorage: sl(),
      channelManager: sl(),
    ),
  );

  sl.registerFactory(
    () => UsersAdminBloc(
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
}
