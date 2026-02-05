import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/user.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;
  final bool needsUpdate;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.needsUpdate = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
    bool? needsUpdate,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      needsUpdate: needsUpdate ?? this.needsUpdate,
    );
  }

  @override
  List<Object?> get props => [isLoading, isAuthenticated, user, error, needsUpdate];
}
