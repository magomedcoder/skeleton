import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Stream<String> call(String sessionId, List<Message> messages) {
    return repository.sendMessage(sessionId, messages);
  }
}
