import 'package:skeleton/domain/entities/message.dart';
import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class SendMessageUseCase {
  final AIChatRepository repository;

  SendMessageUseCase(this.repository);

  Stream<String> call(
    String sessionId,
    List<Message> messages, {
    String? model,
  }) {
    return repository.sendMessage(sessionId, messages, model: model);
  }
}
