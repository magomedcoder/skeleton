import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/domain/repositories/chat_repository.dart';

class UpdateSessionModelUseCase {
  final ChatRepository repository;

  UpdateSessionModelUseCase(this.repository);

  Future<ChatSession> call(String sessionId, String model) {
    return repository.updateSessionModel(sessionId, model);
  }
}
