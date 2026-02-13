import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final int createdAt;
  final int assigner;
  final int executor;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.assigner,
    required this.executor,
  });

  @override
  List<Object?> get props => [id, projectId, name, description, createdAt, assigner, executor];
}
