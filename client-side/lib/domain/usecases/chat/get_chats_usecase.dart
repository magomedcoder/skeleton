import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class GetChatsUseCase {
  final ChatRepository repo;

  GetChatsUseCase(this.repo);

  Future<List<Chat>> call() => repo.getChats();
}
