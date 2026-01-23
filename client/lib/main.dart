import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';
import 'package:legion/presentation/screens/auth/login_screen.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Legion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => di.sl<AuthBloc>(),
          ),
          BlocProvider(
            create: (context) => di.sl<ChatBloc>()..add(const ChatStarted()),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState.isAuthenticated) {
              return const ChatScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}