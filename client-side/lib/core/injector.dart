import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/connection_status.dart';
import 'package:legion/core/server_config.dart';
import 'package:legion/data/services/user_online_status_service.dart';
import 'package:legion/data/data_sources/local/session_model_local_data_source.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/data/data_sources/remote/account_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/ai_chat_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/editor_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/project_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/runners_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/search_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/user_remote_datasource.dart';
import 'package:legion/data/repositories/ai_chat_repository_impl.dart';
import 'package:legion/data/repositories/account_repository_impl.dart';
import 'package:legion/data/repositories/auth_repository_impl.dart';
import 'package:legion/data/repositories/editor_repository_impl.dart';
import 'package:legion/data/repositories/project_repository_impl.dart';
import 'package:legion/data/repositories/runners_repository_impl.dart';
import 'package:legion/data/repositories/user_chat_repository_impl.dart';
import 'package:legion/data/repositories/user_repository_impl.dart';
import 'package:legion/data/services/pts_sync_service.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';
import 'package:legion/domain/repositories/account_repository.dart';
import 'package:legion/domain/repositories/auth_repository.dart';
import 'package:legion/domain/repositories/editor_repository.dart';
import 'package:legion/domain/repositories/project_repository.dart';
import 'package:legion/domain/repositories/runners_repository.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';
import 'package:legion/domain/repositories/user_repository.dart';
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
import 'package:legion/domain/usecases/account/change_password_usecase.dart';
import 'package:legion/domain/usecases/account/get_devices_usecase.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/domain/usecases/account/revoke_device_usecase.dart';
import 'package:legion/domain/usecases/editor/transform_text_usecase.dart';
import 'package:legion/domain/usecases/project/add_user_to_project_usecase.dart';
import 'package:legion/domain/usecases/project/create_project_usecase.dart';
import 'package:legion/domain/usecases/project/create_task_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_members_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_usecase.dart';
import 'package:legion/domain/usecases/project/get_projects_usecase.dart';
import 'package:legion/domain/usecases/project/get_task_usecase.dart';
import 'package:legion/domain/usecases/project/get_tasks_usecase.dart';
import 'package:legion/domain/usecases/project/edit_task_column_id_usecase.dart';
import 'package:legion/domain/usecases/project/edit_task_usecase.dart';
import 'package:legion/domain/usecases/project/get_task_comments_usecase.dart';
import 'package:legion/domain/usecases/project/add_task_comment_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_columns_usecase.dart';
import 'package:legion/domain/usecases/project/create_project_column_usecase.dart';
import 'package:legion/domain/usecases/project/edit_project_column_usecase.dart';
import 'package:legion/domain/usecases/project/delete_project_column_usecase.dart';
import 'package:legion/domain/usecases/project/get_project_history_usecase.dart';
import 'package:legion/domain/usecases/project/get_task_history_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chats_usecase.dart';
import 'package:legion/domain/usecases/chat/create_chat_usecase.dart';
import 'package:legion/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_status_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_usecase.dart';
import 'package:legion/domain/usecases/runners/set_runner_enabled_usecase.dart';
import 'package:legion/domain/usecases/search/search_users_usecase.dart';
import 'package:legion/domain/usecases/users/create_user_usecase.dart';
import 'package:legion/domain/usecases/users/edit_user_usecase.dart';
import 'package:legion/domain/usecases/users/get_users_usecase.dart';
import 'package:legion/presentation/cubit/theme/theme_cubit.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_bloc.dart';
import 'package:legion/presentation/screens/admin/bloc/users_admin_bloc.dart';
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:legion/presentation/screens/tasks/bloc/task_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<UserLocalDataSourceImpl>(
    () => UserLocalDataSourceImpl(),
  );
  await sl<UserLocalDataSourceImpl>().init();

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  await sl<ServerConfig>().init();

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<UserLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<AuthGuard>(
    () => AuthGuard(() async {
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
    }),
  );

  sl.registerLazySingleton<GrpcChannelManager>(
    () => GrpcChannelManager(sl<ServerConfig>(), sl<AuthInterceptor>()),
  );

  sl.registerLazySingleton<ConnectionStatusService>(
    () => ConnectionStatusService(),
  );

  sl.registerLazySingleton<UserOnlineStatusService>(
    () => UserOnlineStatusService(),
  );

  sl.registerLazySingleton<StreamController<Message>>(
    () => StreamController<Message>.broadcast(),
  );

  sl.registerLazySingleton<PtsSyncService>(
    () => PtsSyncService(
      sl<IAccountRemoteDataSource>(),
      sl<UserLocalDataSourceImpl>(),
      sl<GetChatsUseCase>(),
      sl<ConnectionStatusService>(),
      userOnlineStatusService: sl<UserOnlineStatusService>(),
      newMessageSink: sl<StreamController<Message>>().sink,
    ),
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
    () => AuthRemoteDataSource(
      sl<GrpcChannelManager>(),
    ),
  );

  sl.registerLazySingleton<IAccountRemoteDataSource>(
    () => AccountRemoteDataSource(
      sl<GrpcChannelManager>(),
      sl<UserLocalDataSourceImpl>(),
      sl<ConnectionStatusService>(),
    ),
  );

  sl.registerLazySingleton<IUserRemoteDataSource>(
    () => UserRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<ISearchRemoteDataSource>(
    () => SearchRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IProjectRemoteDataSource>(
    () => ProjectRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IRunnersRemoteDataSource>(
    () => RunnersRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<EditorRepository>(() => EditorRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerLazySingleton<AIChatRepository>(
        () => AIChatRepositoryImpl(sl(), sl<SessionModelLocalDataSource>()),
  );
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<IChatRemoteDataSource>()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl<IProjectRemoteDataSource>()),
  );
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
  sl.registerFactory(
    () => ChangePasswordUseCase(
      sl<AccountRepositoryImpl>(),
      sl<UserLocalDataSourceImpl>(),
    ),
  );
  sl.registerFactory(() => GetDevicesUseCase(sl()));
  sl.registerFactory(() => RevokeDeviceUseCase(sl()));

  sl.registerFactory(() => GetUsersUseCase(sl()));
  sl.registerFactory(() => CreateUserUseCase(sl()));
  sl.registerFactory(() => EditUserUseCase(sl()));
  sl.registerFactory(() => SearchUsersUseCase(sl<ISearchRemoteDataSource>()));

  sl.registerFactory(() => CreateProjectUseCase(sl()));
  sl.registerFactory(() => GetProjectsUseCase(sl()));
  sl.registerFactory(() => GetProjectUseCase(sl()));
  sl.registerFactory(() => AddUserToProjectUseCase(sl()));
  sl.registerFactory(() => GetProjectMembersUseCase(sl()));
  sl.registerFactory(() => CreateTaskUseCase(sl()));
  sl.registerFactory(() => GetTasksUseCase(sl()));
  sl.registerFactory(() => GetTaskUseCase(sl()));
  sl.registerFactory(() => EditTaskColumnIdUseCase(sl()));
  sl.registerFactory(() => EditTaskUseCase(sl()));
  sl.registerFactory(() => GetTaskCommentsUseCase(sl()));
  sl.registerFactory(() => AddTaskCommentUseCase(sl()));
  sl.registerFactory(() => GetProjectColumnsUseCase(sl()));
  sl.registerFactory(() => CreateProjectColumnUseCase(sl()));
  sl.registerFactory(() => EditProjectColumnUseCase(sl()));
  sl.registerFactory(() => DeleteProjectColumnUseCase(sl()));
  sl.registerFactory(() => GetProjectHistoryUseCase(sl()));
  sl.registerFactory(() => GetTaskHistoryUseCase(sl()));
  sl.registerFactory(() => GetChatsUseCase(sl()));
  sl.registerFactory(() => CreateChatUseCase(sl()));
  sl.registerFactory(() => GetChatMessagesUseCase(sl()));
  sl.registerFactory(() => SendChatMessageUseCase(sl()));

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
    () => ChatBloc(
      getChatsUseCase: sl(),
      createChatUseCase: sl(),
      getChatMessagesUseCase: sl(),
      sendChatMessageUseCase: sl(),
      newMessageStream: sl<StreamController<Message>>().stream,
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
      ptsSyncService: sl<PtsSyncService>(),
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
    () => DevicesBloc(getDevicesUseCase: sl(), revokeDeviceUseCase: sl()),
  );

  sl.registerFactory(
    () => ProjectBloc(
      getProjectsUseCase: sl(),
      createProjectUseCase: sl(),
      getProjectUseCase: sl(),
      getProjectMembersUseCase: sl(),
      addUserToProjectUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TaskBloc(
      getTasksUseCase: sl(),
      createTaskUseCase: sl(),
      editTaskColumnIdUseCase: sl(),
      editTaskUseCase: sl(),
    ),
  );

  sl.registerFactory(() => ThemeCubit(sl<UserLocalDataSourceImpl>()));
}
