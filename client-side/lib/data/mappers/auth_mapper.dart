import 'package:skeleton/domain/entities/auth_result.dart';
import 'package:skeleton/domain/entities/auth_tokens.dart';
import 'package:skeleton/generated/grpc_pb/auth.pb.dart' as grpc;
import 'package:skeleton/data/mappers/user_mapper.dart';

abstract class AuthMapper {
  AuthMapper._();

  static AuthResult loginResponseFromProto(grpc.LoginResponse proto) {
    return AuthResult(
      user: UserMapper.fromProto(proto.user),
      tokens: AuthTokens(
        accessToken: proto.accessToken,
        refreshToken: proto.refreshToken,
      ),
    );
  }

  static AuthTokens refreshTokenResponseFromProto(
    grpc.RefreshTokenResponse proto,
  ) {
    return AuthTokens(
      accessToken: proto.accessToken,
      refreshToken: proto.refreshToken,
    );
  }
}
