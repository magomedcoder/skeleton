import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String name;

  const User({
    required this.id,
    required this.username,
    required this.name,
  });

  @override
  List<Object?> get props => [id, username, name];
}
