import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class GetSessionModelUseCase {
  final AIChatRepository repository;

  GetSessionModelUseCase(this.repository);

  Future<String?> call(String sessionId) {
    return repository.getSessionModel(sessionId);
  }
}
