import 'package:legion/domain/repositories/chat_repository.dart';

class GetSessionModelUseCase {
  final ChatRepository repository;

  GetSessionModelUseCase(this.repository);

  Future<String?> call(String sessionId) {
    return repository.getSessionModel(sessionId);
  }
}
