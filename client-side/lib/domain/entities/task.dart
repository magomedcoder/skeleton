import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final int createdAt;
  final int assigner;
  final int executor;
  final String columnId;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.assigner,
    required this.executor,
    this.columnId = '',
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    int? createdAt,
    int? assigner,
    int? executor,
    String? columnId,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      assigner: assigner ?? this.assigner,
      executor: executor ?? this.executor,
      columnId: columnId ?? this.columnId,
    );
  }

  @override
  List<Object?> get props => [id, projectId, name, description, createdAt, assigner, executor, columnId];
}
