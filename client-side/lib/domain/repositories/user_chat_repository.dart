import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Chat> createChat(String userId);

  Future<List<Chat>> getChats({required int page, required int pageSize});

  Future<Message> sendMessage({
    required String chatId,
    required String content,
  });

  Future<List<Message>> getMessages({
    required String chatId,
    required int page,
    required int pageSize,
  });
}
