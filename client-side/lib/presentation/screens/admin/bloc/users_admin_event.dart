import 'package:equatable/equatable.dart';

sealed class UsersAdminEvent extends Equatable {
  const UsersAdminEvent();

  @override
  List<Object?> get props => [];
}

class UsersAdminLoadRequested extends UsersAdminEvent {
  final int page;
  final int pageSize;

  const UsersAdminLoadRequested({this.page = 1, this.pageSize = 50});

  @override
  List<Object?> get props => [page, pageSize];
}

class UsersAdminCreateRequested extends UsersAdminEvent {
  final String username;
  final String password;
  final String name;
  final String surname;
  final int role;

  const UsersAdminCreateRequested({
    required this.username,
    required this.password,
    required this.name,
    required this.surname,
    required this.role,
  });

  @override
  List<Object?> get props => [username, password, name, surname, role];
}

class UsersAdminUpdateRequested extends UsersAdminEvent {
  final String id;
  final String username;
  final String password;
  final String name;
  final String surname;
  final int role;

  const UsersAdminUpdateRequested({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.surname,
    required this.role,
  });

  @override
  List<Object?> get props => [id, username, password, name, surname, role];
}

class UsersAdminClearError extends UsersAdminEvent {
  const UsersAdminClearError();
}
