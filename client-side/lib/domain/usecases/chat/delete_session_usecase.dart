import 'package:legion/domain/repositories/chat_repository.dart';

class DeleteSessionUseCase {
  final ChatRepository repository;

  DeleteSessionUseCase(this.repository);

  Future<void> call(String sessionId) {
    return repository.deleteSession(sessionId);
  }
}
