import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class UpdateSessionModelUseCase {
  final AIChatRepository repository;

  UpdateSessionModelUseCase(this.repository);

  Future<ChatSession> call(String sessionId, String model) {
    return repository.updateSessionModel(sessionId, model);
  }
}
