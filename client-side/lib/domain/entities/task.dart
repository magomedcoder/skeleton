import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final int createdAt;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, projectId, name, description, createdAt];
}
