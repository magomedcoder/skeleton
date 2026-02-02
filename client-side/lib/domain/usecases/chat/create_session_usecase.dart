import 'package:legion/domain/entities/session.dart';
import 'package:legion/domain/repositories/chat_repository.dart';

class CreateSessionUseCase {
  final ChatRepository repository;

  CreateSessionUseCase(this.repository);

  Future<ChatSession> call({String? title, String? model}) async {
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
