import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class UpdateSessionTitleUseCase {
  final AIChatRepository repository;

  UpdateSessionTitleUseCase(this.repository);

  Future<ChatSession> call(String sessionId, String title) {
    return repository.updateSessionTitle(sessionId, title);
  }
}
