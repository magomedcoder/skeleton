import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;

class ChatMapper {
  static Chat fromProto(chatpb.Chat chat, [User? user]) {
    final peerUserId = chat.peer.userId.toInt();
    return Chat(
      id: peerUserId.toString(),
      userId: peerUserId.toString(),
      userUsername: user?.username ?? '',
      userName: user?.name ?? '',
      userSurname: user?.surname ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        chat.updatedAt.toInt() * 1000,
      ),
      unreadCount: chat.unreadCount,
    );
  }

  static List<Chat> listFromProto(
    Iterable<chatpb.Chat> chats,
    Map<int, User> userById,
  ) {
    return chats.map((c) {
      final peerId = c.peer.userId.toInt();
      return fromProto(c, userById[peerId]);
    }).toList();
  }
}
