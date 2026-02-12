import 'package:legion/domain/entities/project.dart';
import 'package:legion/generated/grpc_pb/project.pb.dart' as projectpb;

class ProjectMapper {
  static Project fromProto(projectpb.Project proto) {
    return Project(id: proto.id, name: proto.name);
  }

  static List<Project> listFromProto(Iterable<projectpb.Project> list) {
    return list.map(fromProto).toList();
  }
}
