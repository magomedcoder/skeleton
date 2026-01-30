import 'package:legion/domain/entities/session.dart';
import 'package:legion/domain/repositories/chat_repository.dart';

class CreateSessionUseCase {
  final ChatRepository repository;

  CreateSessionUseCase(this.repository);

  Future<ChatSession> call({String? title, String? model}) async {
    final sessionTitle = title ?? 'Чат от ${DateTime.now().toString()}';
    return await repository.createSession(sessionTitle, model: model);
  }
}
