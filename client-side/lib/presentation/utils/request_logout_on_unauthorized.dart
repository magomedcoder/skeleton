import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_event.dart';

void requestLogoutIfUnauthorized(Object e, AuthBloc authBloc) {
  if (e is UnauthorizedFailure) {
    Logs().w('requestLogoutIfUnauthorized: сессия не авторизована, запрос выхода');
    authBloc.add(const AuthLogoutRequested());
  }
}
