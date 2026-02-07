import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class DeleteSessionUseCase {
  final AIChatRepository repository;

  DeleteSessionUseCase(this.repository);

  Future<void> call(String sessionId) {
    return repository.deleteSession(sessionId);
  }
}
