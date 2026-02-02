import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final String host;
  final int port;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    required this.host,
    required this.port,
  });

  @override
  List<Object?> get props => [username, password, host, port];
}

class AuthRefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const AuthRefreshTokenRequested(this.refreshToken);

  @override
  List<Object?> get props => [refreshToken];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthClearError extends AuthEvent {
  const AuthClearError();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthRefreshTokenInBackground extends AuthEvent {
  const AuthRefreshTokenInBackground();
}

class AuthClearNeedsUpdate extends AuthEvent {
  const AuthClearNeedsUpdate();
}
