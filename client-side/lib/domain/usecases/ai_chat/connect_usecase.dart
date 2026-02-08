import 'package:legion/domain/repositories/ai_chat_repository.dart';

class ConnectUseCase {
  final AIChatRepository repository;

  ConnectUseCase(this.repository);

  Future<bool> call() => repository.checkConnection();
}
