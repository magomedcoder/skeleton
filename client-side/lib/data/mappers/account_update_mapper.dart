import 'package:legion/domain/entities/account_update.dart';
import 'package:legion/generated/grpc_pb/account.pb.dart' as grpc;

abstract class AccountUpdateMapper {
  AccountUpdateMapper._();

  static AccountUpdate? fromGrpc(grpc.Update proto) {
    if (proto.hasUserStatus()) {
      final us = proto.userStatus;
      return UserStatusAccountUpdate(
        userId: us.userId.toInt(),
        status: us.status,
      );
    }
    return null;
  }
}
