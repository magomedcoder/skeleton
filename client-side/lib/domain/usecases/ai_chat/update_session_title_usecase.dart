import 'package:skeleton/domain/entities/ai_chat_session.dart';
import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class UpdateSessionTitleUseCase {
  final AIChatRepository repository;

  UpdateSessionTitleUseCase(this.repository);

  Future<AIChatSession> call(String sessionId, String title) {
    return repository.updateSessionTitle(sessionId, title);
  }
}
