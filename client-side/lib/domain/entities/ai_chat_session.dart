import 'package:equatable/equatable.dart';

class AIChatSession extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? model;

  const AIChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.model,
  });

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, model];
}
