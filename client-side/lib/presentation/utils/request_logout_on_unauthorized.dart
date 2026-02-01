import 'package:legion/core/failures.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_event.dart';

void requestLogoutIfUnauthorized(Object e, AuthBloc authBloc) {
  if (e is UnauthorizedFailure) {
    authBloc.add(const AuthLogoutRequested());
  }
}
