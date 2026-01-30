import 'package:legion/domain/repositories/chat_repository.dart';

class SetSessionModelUseCase {
  final ChatRepository repository;

  SetSessionModelUseCase(this.repository);

  Future<void> call(String sessionId, String model) {
    return repository.setSessionModel(sessionId, model);
  }
}
