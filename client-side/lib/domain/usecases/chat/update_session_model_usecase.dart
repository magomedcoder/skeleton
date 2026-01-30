import 'package:legion/domain/entities/session.dart';
import 'package:legion/domain/repositories/chat_repository.dart';

class UpdateSessionModelUseCase {
  final ChatRepository repository;

  UpdateSessionModelUseCase(this.repository);

  Future<ChatSession> call(String sessionId, String model) {
    return repository.updateSessionModel(sessionId, model);
  }
}
