import 'package:legion/domain/repositories/editor_repository.dart';
import 'package:legion/generated/grpc_pb/editor.pb.dart' as grpc;

class TransformTextUseCase {
  final EditorRepository repository;

  TransformTextUseCase(this.repository);

  Future<String> call({
    required String text,
    required grpc.TransformType type,
    String? model,
    bool preserveMarkdown = false,
  }) {
    return repository.transform(
      text: text,
      type: type,
      model: model,
      preserveMarkdown: preserveMarkdown,
    );
  }
}
