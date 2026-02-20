import 'package:legion/domain/entities/message.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;

class MessageMapper {
  static Message fromProto(chatpb.Message msg) {
    return Message(
      id: msg.id.toInt(),
      peerUserId: msg.peer.userId.toInt(),
      fromPeerUserId: msg.fromPeer.userId.toInt(),
      content: msg.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        msg.createdAt.toInt() * 1000,
      ),
    );
  }

  static List<Message> listFromProto(Iterable<chatpb.Message> messages) {
    return messages.map(fromProto).toList();
  }
}
