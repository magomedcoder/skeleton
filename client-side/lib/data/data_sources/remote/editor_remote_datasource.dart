import 'package:grpc/grpc.dart';
import 'package:skeleton/core/auth_guard.dart';
import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/grpc_channel_manager.dart';
import 'package:skeleton/core/grpc_error_handler.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/generated/grpc_pb/editor.pbgrpc.dart' as grpc;

abstract class IEditorRemoteDataSource {
  Future<String> transform({
    required String text,
    String? model,
  });
}

class EditorRemoteDataSource implements IEditorRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  EditorRemoteDataSource(this._channelManager, this._authGuard);

  grpc.EditorServiceClient get _client => _channelManager.editorClient;

  @override
  Future<String> transform({required String text, String? model}) async {
    Logs().d('EditorRemoteDataSource: transform model=$model');
    try {
      final request = grpc.TransformRequest(text: text);

      if (model != null && model.isNotEmpty) {
        request.model = model;
      }

      final resp = await _authGuard.execute(() => _client.transform(request));
      return resp.text;
    } on GrpcError catch (e) {
      Logs().e('EditorRemoteDataSource: ошибка transform', e);
      throwGrpcError(e, 'Ошибка обработки текста');
    } catch (e) {
      Logs().e('EditorRemoteDataSource: ошибка transform', e);
      throw ApiFailure('Ошибка обработки текста');
    }
  }
}
