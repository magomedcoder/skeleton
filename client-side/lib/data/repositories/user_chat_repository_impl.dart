import 'package:legion/core/failures.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/repositories/user_chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final IChatRemoteDataSource _remote;

  ChatRepositoryImpl(this._remote);

  @override
  Future<Chat> createChat(String userId) async {
    try {
      return await _remote.createChat(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    try {
      return await _remote.getChats();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
  }) async {
    try {
      return await _remote.sendMessage(peerUserId: peerUserId, content: content);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) async {
    try {
      return await _remote.getHistory(
        peerUserId: peerUserId,
        messageId: messageId,
        limit: limit,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getHistory', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }

  @override
  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true}) async {
    if (messageIds.isEmpty) return;
    try {
      await _remote.deleteMessages(messageIds, forEveryone: forEveryone);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }
}
