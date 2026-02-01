import 'package:grpc/grpc.dart';
import 'package:legion/core/failures.dart';

const String kSessionExpiredMessage = 'Сессия истекла, войдите снова';

Never throwGrpcError(
  GrpcError e,
  String networkMessage, {
  String? unauthenticatedMessage,
}) {
  if (e.code == StatusCode.unauthenticated) {
    throw UnauthorizedFailure(unauthenticatedMessage ?? kSessionExpiredMessage);
  }

  throw NetworkFailure(networkMessage);
}
