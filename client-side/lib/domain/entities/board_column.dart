import 'package:equatable/equatable.dart';

class BoardColumn extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String color;
  final String statusKey;
  final int position;

  const BoardColumn({
    required this.id,
    required this.projectId,
    required this.title,
    required this.color,
    required this.statusKey,
    this.position = 0,
  });

  @override
  List<Object?> get props => [id, projectId, title, color, statusKey, position];
}
