import 'package:legion/domain/entities/ai_chat_session.dart';
import 'package:legion/domain/repositories/ai_chat_repository.dart';

class CreateSessionUseCase {
  final AIChatRepository repository;

  CreateSessionUseCase(this.repository);

  Future<AIChatSession> call({String? title, String? model}) async {
    final sessionTitle = title ?? _defaultSessionTitle();
    return await repository.createSession(sessionTitle, model: model);
  }

  static String _defaultSessionTitle() {
    final n = DateTime.now();
    final time = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    final date ='${n.day.toString().padLeft(2, '0')}.${n.month.toString().padLeft(2, '0')}.${n.year}';

    return 'Чат от $time $date';
  }
}
