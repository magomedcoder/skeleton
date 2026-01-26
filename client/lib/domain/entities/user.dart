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

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    username: json['username'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name
  };

  @override
  List<Object?> get props => [id, username, name];
}
