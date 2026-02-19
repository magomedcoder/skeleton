import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repo;

  SendChatMessageUseCase(this.repo);

  Future<Message> call({
    required int peerUserId,
    required String content,
  }) => repo.sendMessage(peerUserId: peerUserId, content: content);
}
