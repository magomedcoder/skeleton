import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/editor_remote_datasource.dart';
import 'package:legion/domain/repositories/editor_repository.dart';
import 'package:legion/generated/grpc_pb/editor.pb.dart' as grpc;

class EditorRepositoryImpl implements EditorRepository {
  final IEditorRemoteDataSource dataSource;

  EditorRepositoryImpl(this.dataSource);

  @override
  Future<String> transform({
    required String text,
    required grpc.TransformType type,
    String? model,
    bool preserveMarkdown = false,
  }) async {
    try {
      return await dataSource.transform(
        text: text,
        type: type,
        model: model,
        preserveMarkdown: preserveMarkdown,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('EditorRepository: неожиданная ошибка transform', e);
      throw ApiFailure('Ошибка обработки текста');
    }
  }
}

