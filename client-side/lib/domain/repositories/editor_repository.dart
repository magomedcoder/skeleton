import 'package:skeleton/generated/grpc_pb/editor.pb.dart' as grpc;

abstract interface class EditorRepository {
  Future<String> transform({
    required String text,
    required grpc.TransformType type,
    String? model,
    bool preserveMarkdown,
  });
}
