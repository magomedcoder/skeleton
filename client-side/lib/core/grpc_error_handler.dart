import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';

const String kSessionExpiredMessage = 'Сессия истекла, войдите снова';

Never throwGrpcError(
  GrpcError e,
  String networkMessage, {
  String? unauthenticatedMessage,
}) {
  if (e.code == StatusCode.unauthenticated) {
    Logs().w('gRPC: unauthenticated', e);
    throw UnauthorizedFailure(unauthenticatedMessage ?? kSessionExpiredMessage);
  }

  Logs().e('gRPC: $networkMessage', e);
  throw NetworkFailure(networkMessage);
}
