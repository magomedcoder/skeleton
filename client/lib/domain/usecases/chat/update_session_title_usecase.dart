import 'package:legion/domain/entities/session.dart';
import 'package:legion/domain/repositories/chat_repository.dart';

class UpdateSessionTitleUseCase {
  final ChatRepository repository;

  UpdateSessionTitleUseCase(this.repository);

  Future<ChatSession> call(String sessionId, String title) {
    return repository.updateSessionTitle(sessionId, title);
  }
}
