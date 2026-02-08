import 'package:legion/domain/entities/ai_chat_session.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';

class GetSessionsUseCase {
  final AIChatRepository repository;

  GetSessionsUseCase(this.repository);

  Future<List<AIChatSession>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getSessions(page, pageSize);
  }
}
