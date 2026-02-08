import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/common.pb.dart' as grpc;

abstract class UserMapper {
  UserMapper._();

  static User fromProto(grpc.User proto) {
    return User(
      id: proto.id,
      username: proto.username,
      name: proto.name,
      surname: proto.surname,
      role: proto.role,
    );
  }

  static List<User> listFromProto(List<grpc.User> protos) {
    return protos.map(fromProto).toList();
  }
}
