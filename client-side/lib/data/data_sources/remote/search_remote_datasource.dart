import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/user_mapper.dart';
import 'package:legion/domain/entities/user.dart';
import 'package:legion/generated/grpc_pb/search.pbgrpc.dart' as searchpb;

abstract class ISearchRemoteDataSource {
  Future<(List<User>, int)> searchUsers({
    required String query,
    required int page,
    required int pageSize,
  });
}

class SearchRemoteDataSource implements ISearchRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  SearchRemoteDataSource(this._channelManager, this._authGuard);

  searchpb.SearchServiceClient get _client => _channelManager.searchClient;

  @override
  Future<(List<User>, int)> searchUsers({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    Logs().d('SearchRemoteDataSource: поиск пользователей query="$query"');
    try {
      final req = searchpb.SearchUsersRequest(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      final resp = await _authGuard.execute(() => _client.users(req));
      final users = UserMapper.listFromProto(resp.users);
      return (users, resp.total);
    } on GrpcError catch (e) {
      Logs().e('SearchRemoteDataSource: ошибка gRPC', e);
      throwGrpcError(e, 'Ошибка поиска пользователей');
    } catch (e) {
      Logs().e('SearchRemoteDataSource: неожиданная ошибка', e);
      throw ApiFailure('Ошибка поиска пользователей');
    }
  }
}
