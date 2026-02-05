import 'package:skeleton/domain/entities/message.dart';
import 'package:skeleton/domain/repositories/chat_repository.dart';

class GetSessionMessagesUseCase {
  final ChatRepository repository;

  GetSessionMessagesUseCase(this.repository);

  Future<List<Message>> call(
    String sessionId, {
    int page = 1,
    int pageSize = 50,
  }) {
    return repository.getSessionMessages(sessionId, page, pageSize);
  }
}
