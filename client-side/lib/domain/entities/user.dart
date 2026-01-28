import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String name;
  final String surname;
  final int role;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    required this.role,
  });

  bool get isAdmin => role == 1;

  @override
  List<Object?> get props => [id, username, name, surname, role];
}
