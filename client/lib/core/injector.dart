import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/data/data_sources/local/auth_local_data_source.dart';
import 'package:legion/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:legion/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:legion/data/repositories/auth_repository_impl.dart';
import 'package:legion/data/repositories/chat_repository_impl.dart';
import 'package:legion/domain/repositories/auth_repository.dart';
import 'package:legion/domain/repositories/chat_repository.dart';
import 'package:legion/domain/usecases/auth/login_usecase.dart';
import 'package:legion/domain/usecases/auth/logout_usecase.dart';
import 'package:legion/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:legion/domain/usecases/chat/connect_usecase.dart';
import 'package:legion/domain/usecases/chat/create_session_usecase.dart';
import 'package:legion/domain/usecases/chat/delete_session_usecase.dart';
import 'package:legion/domain/usecases/chat/get_session_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/get_sessions_usecase.dart';
import 'package:legion/domain/usecases/chat/send_message_usecase.dart';
import 'package:legion/domain/usecases/chat/update_session_title_usecase.dart';
import 'package:legion/generated/grpc_pb/auth.pbgrpc.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AuthLocalDataSourceImpl>(() => AuthLocalDataSourceImpl());
  await sl<AuthLocalDataSourceImpl>().init();

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<AuthLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<ClientChannel>(() {
    return ClientChannel(
      '10.11.61.37',
      port: 50051,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(seconds: 30),
      ),
    );
  });

  sl.registerLazySingleton(() => ChatServiceClient(
        sl<ClientChannel>(),
        interceptors: [sl<AuthInterceptor>()],
      ));
  sl.registerLazySingleton(() => AuthServiceClient(
        sl<ClientChannel>(),
        interceptors: [sl<AuthInterceptor>()],
      ));

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  sl.registerFactory(() => ConnectUseCase(sl()));
  sl.registerFactory(() => SendMessageUseCase(sl()));
  sl.registerFactory(() => CreateSessionUseCase(sl()));
  sl.registerFactory(() => GetSessionsUseCase(sl()));
  sl.registerFactory(() => GetSessionMessagesUseCase(sl()));
  sl.registerFactory(() => DeleteSessionUseCase(sl()));
  sl.registerFactory(() => UpdateSessionTitleUseCase(sl()));

  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));

  sl.registerFactory(
    () => ChatBloc(
      connectUseCase: sl(),
      sendMessageUseCase: sl(),
      createSessionUseCase: sl(),
      getSessionsUseCase: sl(),
      getSessionMessagesUseCase: sl(),
      deleteSessionUseCase: sl(),
      updateSessionTitleUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      refreshTokenUseCase: sl(),
      logoutUseCase: sl(),
      tokenStorage: sl(),
    ),
  );
}
