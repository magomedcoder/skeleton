import 'package:legion/domain/entities/ai_chat_session.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';

class UpdateSessionModelUseCase {
  final AIChatRepository repository;

  UpdateSessionModelUseCase(this.repository);

  Future<AIChatSession> call(String sessionId, String model) {
    return repository.updateSessionModel(sessionId, model);
  }
}
