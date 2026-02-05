import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/auth_tokens.dart';
import 'package:skeleton/domain/entities/user.dart';

class AuthResult extends Equatable {
  final User user;
  final AuthTokens tokens;

  const AuthResult({
    required this.user,
    required this.tokens,
  });

  @override
  List<Object?> get props => [user, tokens];
}
