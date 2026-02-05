import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/core/server_config.dart';
import 'package:legion/generated/grpc_pb/auth.pbgrpc.dart' as grpc_auth;
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as grpc_chat;
import 'package:legion/generated/grpc_pb/editor.pbgrpc.dart' as grpc_editor;
import 'package:legion/generated/grpc_pb/runner.pbgrpc.dart' as grpc_runner;
import 'package:legion/generated/grpc_pb/user.pbgrpc.dart' as grpc_user;

class GrpcChannelManager {
  final ServerConfig _config;
  final AuthInterceptor _authInterceptor;

  ClientChannel? _channel;
  grpc_auth.AuthServiceClient? _authClient;
  grpc_auth.AuthServiceClient? _authClientNoInterceptor;
  grpc_chat.ChatServiceClient? _chatClient;
  grpc_editor.EditorServiceClient? _editorClient;
  grpc_user.UserServiceClient? _userClient;
  grpc_runner.RunnerAdminServiceClient? _runnerAdminClient;

  GrpcChannelManager(this._config, this._authInterceptor);

  ClientChannel get channel {
    if (_channel == null) {
      Logs().d('GrpcChannelManager: создание канала ${_config.host}:${_config.port}');
      _channel = ClientChannel(
        _config.host,
        port: _config.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          idleTimeout: Duration(seconds: 30),
        ),
      );
    }
    return _channel!;
  }

  grpc_auth.AuthServiceClient get authClient {
    _authClient ??= grpc_auth.AuthServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _authClient!;
  }

  grpc_chat.ChatServiceClient get chatClient {
    _chatClient ??= grpc_chat.ChatServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _chatClient!;
  }

  grpc_editor.EditorServiceClient get editorClient {
    _editorClient ??= grpc_editor.EditorServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _editorClient!;
  }

  grpc_user.UserServiceClient get userClient {
    _userClient ??= grpc_user.UserServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _userClient!;
  }

  grpc_runner.RunnerAdminServiceClient get runnerAdminClient {
    _runnerAdminClient ??= grpc_runner.RunnerAdminServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _runnerAdminClient!;
  }

  grpc_auth.AuthServiceClient get authClientForVersionCheck {
    _authClientNoInterceptor ??= grpc_auth.AuthServiceClient(channel);
    return _authClientNoInterceptor!;
  }

  Future<void> setServer(String host, int port) async {
    Logs().i('GrpcChannelManager: смена сервера на $host:$port');
    await _config.setServer(host, port);
    await _closeChannel();
  }

  Future<void> _closeChannel() async {
    final ch = _channel;
    _channel = null;
    _authClient = null;
    _authClientNoInterceptor = null;
    _chatClient = null;
    _editorClient = null;
    _userClient = null;
    _runnerAdminClient = null;
    if (ch != null) {
      Logs().d('GrpcChannelManager: закрытие канала');
      await ch.shutdown();
    }
  }
}
