import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repo;

  GetChatMessagesUseCase(this.repo);

  Future<List<Message>> call({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) => repo.getHistory(
    peerUserId: peerUserId,
    messageId: messageId,
    limit: limit,
  );
}
