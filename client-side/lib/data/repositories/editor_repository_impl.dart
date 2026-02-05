import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/data/data_sources/remote/editor_remote_datasource.dart';
import 'package:skeleton/domain/repositories/editor_repository.dart';
import 'package:skeleton/generated/grpc_pb/editor.pb.dart' as grpc;

class EditorRepositoryImpl implements EditorRepository {
  final IEditorRemoteDataSource dataSource;

  EditorRepositoryImpl(this.dataSource);

  @override
  Future<String> transform({
    required String text,
    String? model,
  }) async {
    try {
      return await dataSource.transform(
        text: text,
        model: model,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('EditorRepository: неожиданная ошибка transform', e);
      throw ApiFailure('Ошибка обработки текста');
    }
  }
}

