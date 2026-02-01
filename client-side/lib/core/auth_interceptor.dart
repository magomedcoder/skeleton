import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';

class AuthInterceptor implements ClientInterceptor {
  final UserLocalDataSourceImpl tokenStorage;

  AuthInterceptor(this.tokenStorage);

  FutureOr<void> _tokenProvider(Map<String, String> metadata, String _) async {
    if (tokenStorage.hasToken) {
      metadata['authorization'] = 'Bearer ${tokenStorage.accessToken}';
      Logs().d('AuthInterceptor: добавлен Bearer токен в запрос');
    }
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    return invoker(
      method,
      request,
      options.mergedWith(CallOptions(providers: [_tokenProvider])),
    );
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    return invoker(
      method,
      requests,
      options.mergedWith(CallOptions(providers: [_tokenProvider])),
    );
  }
}
