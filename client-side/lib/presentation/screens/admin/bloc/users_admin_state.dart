import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/user.dart';

class UsersAdminState extends Equatable {
  static const Object _noChange = Object();

  final bool isLoading;
  final List<User> users;
  final String? error;
  final int currentPage;
  final int pageSize;

  const UsersAdminState({
    this.isLoading = false,
    this.users = const [],
    this.error,
    this.currentPage = 1,
    this.pageSize = 50,
  });

  UsersAdminState copyWith({
    bool? isLoading,
    List<User>? users,
    Object? error = _noChange,
    int? currentPage,
    int? pageSize,
  }) {
    return UsersAdminState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: identical(error, _noChange) ? this.error : error as String?,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [isLoading, users, error, currentPage, pageSize];
}
