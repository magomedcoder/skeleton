import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repo;

  SendChatMessageUseCase(this.repo);

  Future<Message> call({
    required String chatId,
    required String content
  }) => repo.sendMessage(chatId: chatId, content: content);
}
