import 'package:legion/domain/repositories/ai_chat_repository.dart';

class SetSessionModelUseCase {
  final AIChatRepository repository;

  SetSessionModelUseCase(this.repository);

  Future<void> call(String sessionId, String model) {
    return repository.setSessionModel(sessionId, model);
  }
}
