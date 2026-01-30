import 'package:legion/domain/entities/session.dart';
import 'package:legion/generated/grpc_pb/chat.pb.dart' as grpc;

abstract class SessionMapper {
  SessionMapper._();

  static DateTime _dateTimeFromUnixSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static ChatSession fromProto(grpc.ChatSession proto) {
    return ChatSession(
      id: proto.id,
      title: proto.title,
      createdAt: _dateTimeFromUnixSeconds(proto.createdAt.toInt()),
      updatedAt: _dateTimeFromUnixSeconds(proto.updatedAt.toInt()),
    );
  }

  static List<ChatSession> listFromProto(List<grpc.ChatSession> protos) {
    return protos.map(fromProto).toList();
  }
}
