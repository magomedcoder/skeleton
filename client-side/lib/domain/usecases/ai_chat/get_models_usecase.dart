import 'package:skeleton/domain/repositories/ai_chat_repository.dart';

class GetModelsUseCase {
  final AIChatRepository repository;

  GetModelsUseCase(this.repository);

  Future<List<String>> call() {
    return repository.getModels();
  }
}
