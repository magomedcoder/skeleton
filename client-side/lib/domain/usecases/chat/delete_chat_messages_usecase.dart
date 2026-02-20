import 'package:legion/domain/repositories/user_chat_repository.dart';

class DeleteChatMessagesUseCase {
  final ChatRepository repo;

  DeleteChatMessagesUseCase(this.repo);

  Future<void> call(List<int> messageIds, {bool forEveryone = true}) => repo.deleteMessages(messageIds, forEveryone: forEveryone);
}
