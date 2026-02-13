import 'package:legion/domain/entities/task.dart';
import 'package:legion/generated/grpc_pb/project.pb.dart' as projectpb;

class TaskMapper {
  static Task fromProto(projectpb.Task proto, {String projectId = ''}) {
    return Task(
      id: proto.id,
      projectId: projectId,
      name: proto.name,
      description: proto.description,
      createdAt: proto.createdAt.toInt(),
    );
  }

  static List<Task> listFromProto(
    Iterable<projectpb.Task> list, {
    String projectId = '',
  }) {
    return list.map((task) => fromProto(task, projectId: projectId)).toList();
  }
}
