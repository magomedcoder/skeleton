import 'package:legion/data/data_sources/remote/search_remote_datasource.dart';
import 'package:legion/domain/entities/user.dart';

class SearchUsersUseCase {
  final ISearchRemoteDataSource remote;

  SearchUsersUseCase(this.remote);

  Future<(List<User>, int)> call({
    required String query,
    required int page,
    required int pageSize,
  }) {
    return remote.searchUsers(
      query: query, 
      page: page,
      pageSize: pageSize,
    );
  }
}
