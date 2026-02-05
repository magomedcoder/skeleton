import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/domain/repositories/chat_repository.dart';

class GetSessionsUseCase {
  final ChatRepository repository;

  GetSessionsUseCase(this.repository);

  Future<List<ChatSession>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getSessions(page, pageSize);
  }
}
