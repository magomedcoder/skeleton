import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_event.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/editor/bloc/editor_bloc.dart';
import 'package:legion/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders {
  static List<BlocProvider> get blocProviders => [
    BlocProvider<AuthBloc>(
      create: (context) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
    ),
    BlocProvider<AIChatBloc>(create: (context) => di.sl<AIChatBloc>()),
    BlocProvider<EditorBloc>(create: (context) => di.sl<EditorBloc>()),
    BlocProvider<ChatBloc>(create: (context) => di.sl<ChatBloc>()),
    BlocProvider<ProjectBloc>(create: (context) => di.sl<ProjectBloc>()),
  ];

  static List<SingleChildWidget> get allProviders => [
    ...blocProviders,
  ];
}