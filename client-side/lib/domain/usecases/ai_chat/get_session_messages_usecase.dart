import 'package:legion/domain/entities/ai_message.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';

class GetSessionMessagesUseCase {
  final AIChatRepository repository;

  GetSessionMessagesUseCase(this.repository);

  Future<List<AIMessage>> call(
    String sessionId, {
    int page = 1,
    int pageSize = 50,
  }) {
    return repository.getSessionMessages(sessionId, page, pageSize);
  }
}
