import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Chat> createChat(String userId);

  Future<List<Chat>> getChats();

  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
  });

  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});
}
