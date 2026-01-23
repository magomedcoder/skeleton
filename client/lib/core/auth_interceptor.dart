import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:legion/core/token_storage.dart';

class AuthInterceptor implements ClientInterceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor(this.tokenStorage);

  FutureOr<void> _tokenProvider(Map<String, String> metadata, String _) async {
    if (tokenStorage.hasToken) {
      metadata['authorization'] = 'Bearer ${tokenStorage.accessToken}';
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
