import 'package:legion/domain/repositories/editor_repository.dart';

class TransformTextUseCase {
  final EditorRepository repository;

  TransformTextUseCase(this.repository);

  Future<String> call({
    required String text,
    String? model,
  }) {
    return repository.transform(
      text: text,
      model: model,
    );
  }
}
