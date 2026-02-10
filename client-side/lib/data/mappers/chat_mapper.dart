import 'package:legion/domain/entities/chat.dart';
import 'package:legion/generated/grpc_pb/chat.pb.dart' as chatpb;

class ChatMapper {
  static Chat fromProto(chatpb.Chat chat) {
    final user = chat.user;
    return Chat(
      id: chat.id,
      userId: user.id,
      userUsername: user.username,
      userName: user.name,
      userSurname: user.surname,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        chat.createdAt.toInt() * 1000,
      ),
    );
  }

  static List<Chat> listFromProto(Iterable<chatpb.Chat> chats) {
    return chats.map(fromProto).toList();
  }
}
