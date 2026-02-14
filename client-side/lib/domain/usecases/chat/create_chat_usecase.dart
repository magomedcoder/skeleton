import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class CreateChatUseCase {
  final ChatRepository repo;

  CreateChatUseCase(this.repo);

  Future<Chat> call(String userId) => repo.createChat(userId);
}
