import 'package:skeleton/domain/entities/ai_message.dart';
import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class SendMessageUseCase {
  final AIChatRepository repository;

  SendMessageUseCase(this.repository);

  Stream<String> call(
    String sessionId,
    List<AIMessage> messages, {
    String? model,
  }) {
    return repository.sendMessage(sessionId, messages, model: model);
  }
}
