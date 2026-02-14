import 'package:legion/domain/entities/board_column.dart';
import 'package:legion/generated/grpc_pb/project.pb.dart' as projectpb;

class BoardColumnMapper {
  static BoardColumn fromProto(projectpb.ProjectColumn proto) {
    return BoardColumn(
      id: proto.id,
      projectId: proto.projectId,
      title: proto.title,
      color: proto.color.isNotEmpty ? proto.color : '#9E9E9E',
      statusKey: proto.statusKey.isNotEmpty ? proto.statusKey : 'todo',
      position: proto.position.toInt(),
    );
  }

  static List<BoardColumn> listFromProto(Iterable<projectpb.ProjectColumn> list) {
    return list.map(fromProto).toList();
  }
}
