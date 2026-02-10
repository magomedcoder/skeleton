import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_interceptor.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/core/server_config.dart';
import 'package:legion/generated/grpc_pb/auth.pbgrpc.dart' as authpb;
import 'package:legion/generated/grpc_pb/aichat.pbgrpc.dart' as aichatpb;
import 'package:legion/generated/grpc_pb/editor.pbgrpc.dart' as editorpb;
import 'package:legion/generated/grpc_pb/runner.pbgrpc.dart' as runnerpb;
import 'package:legion/generated/grpc_pb/user.pbgrpc.dart' as userpb;
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:legion/generated/grpc_pb/search.pbgrpc.dart' as searchpb;

class GrpcChannelManager {
  final ServerConfig _config;
  final AuthInterceptor _authInterceptor;

  ClientChannel? _channel;
  authpb.AuthServiceClient? _authClient;
  authpb.AuthServiceClient? _authClientNoInterceptor;
  aichatpb.AIChatServiceClient? _aiChatClient;
  editorpb.EditorServiceClient? _editorClient;
  userpb.UserServiceClient? _userClient;
  runnerpb.RunnerAdminServiceClient? _runnerAdminClient;
  chatpb.ChatServiceClient? _chatClient;
  searchpb.SearchServiceClient? _searchClient;

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

  authpb.AuthServiceClient get authClient {
    _authClient ??= authpb.AuthServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _authClient!;
  }

  aichatpb.AIChatServiceClient get aiChatClient {
    _aiChatClient ??= aichatpb.AIChatServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _aiChatClient!;
  }

  editorpb.EditorServiceClient get editorClient {
    _editorClient ??= editorpb.EditorServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _editorClient!;
  }

  userpb.UserServiceClient get userClient {
    _userClient ??= userpb.UserServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _userClient!;
  }

  runnerpb.RunnerAdminServiceClient get runnerAdminClient {
    _runnerAdminClient ??= runnerpb.RunnerAdminServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _runnerAdminClient!;
  }

  authpb.AuthServiceClient get authClientForVersionCheck {
    _authClientNoInterceptor ??= authpb.AuthServiceClient(channel);
    return _authClientNoInterceptor!;
  }

  chatpb.ChatServiceClient get chatClient {
    _chatClient ??= chatpb.ChatServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _chatClient!;
  }

  searchpb.SearchServiceClient get searchClient {
    _searchClient ??= searchpb.SearchServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _searchClient!;
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
    _aiChatClient = null;
    _editorClient = null;
    _userClient = null;
    _runnerAdminClient = null;
    _chatClient = null;
    _searchClient = null;
    if (ch != null) {
      Logs().d('GrpcChannelManager: закрытие канала');
      await ch.shutdown();
    }
  }
}
