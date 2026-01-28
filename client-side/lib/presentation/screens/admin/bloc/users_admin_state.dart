import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/user.dart';

class UsersAdminState extends Equatable {
  final bool isLoading;
  final List<User> users;
  final String? error;

  const UsersAdminState({
    this.isLoading = false,
    this.users = const [],
    this.error,
  });

  UsersAdminState copyWith({
    bool? isLoading,
    List<User>? users,
    String? error,
  }) {
    return UsersAdminState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, users, error];
}
