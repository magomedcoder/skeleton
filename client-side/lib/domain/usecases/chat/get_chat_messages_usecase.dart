import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repo;

  GetChatMessagesUseCase(this.repo);

  Future<List<Message>> call({
    required String chatId,
    required int page,
    required int pageSize,
  }) =>repo.getMessages(chatId: chatId, page: page, pageSize: pageSize);
}
