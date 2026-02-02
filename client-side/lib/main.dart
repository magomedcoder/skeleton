import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/core/log/logs.dart';
import 'package:legion/core/theme/app_theme.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_event.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';
import 'package:legion/presentation/screens/auth/login_screen.dart';
import 'package:legion/presentation/screens/auth/update_required_screen.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/main_layout.dart';
import 'package:legion/presentation/theme/theme_cubit.dart';
import 'package:legion/presentation/theme/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logs().i('Запуск приложения');
  await di.init();
  Logs().i('Инициализация завершена');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final primary = AppTheme.primaryFromId(themeState.accentColorId);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Legion',
            theme: AppTheme.themeLight(primary),
            darkTheme: AppTheme.themeDark(primary),
            themeMode: themeState.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru')],
            home: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
                ),
                BlocProvider(
                  create: (context) => di.sl<ChatBloc>(),
                ),
              ],
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState.needsUpdate) {
                    return const UpdateRequiredScreen();
                  }
                  if (authState.isLoading && !authState.isAuthenticated) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (authState.isAuthenticated) {
                    return const MainLayout();
                  }
                  return const LoginScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}