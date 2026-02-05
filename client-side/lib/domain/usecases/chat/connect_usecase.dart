import 'package:skeleton/domain/repositories/chat_repository.dart';

class ConnectUseCase {
  final ChatRepository repository;

  ConnectUseCase(this.repository);

  Future<bool> call() => repository.checkConnection();
}
