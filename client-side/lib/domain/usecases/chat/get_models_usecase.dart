import 'package:skeleton/domain/repositories/chat_repository.dart';

class GetModelsUseCase {
  final ChatRepository repository;

  GetModelsUseCase(this.repository);

  Future<List<String>> call() {
    return repository.getModels();
  }
}
