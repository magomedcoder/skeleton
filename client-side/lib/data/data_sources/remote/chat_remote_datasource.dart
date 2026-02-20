import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/chat_mapper.dart';
import 'package:legion/data/mappers/message_mapper.dart';
import 'package:legion/data/mappers/user_mapper.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:legion/generated/grpc_pb/common.pb.dart' as commonpb;

abstract class IChatRemoteDataSource {
  Future<Chat> createChat(String userId);

  Future<List<Chat>> getChats();

  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
  });

  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});
}

class ChatRemoteDataSource implements IChatRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ChatRemoteDataSource(this._channelManager, this._authGuard);

  chatpb.ChatServiceClient get _client => _channelManager.chatClient;

  @override
  Future<Chat> createChat(String userId) async {
    Logs().d('ChatRemoteDataSource: createChat userId=$userId');
    try {
      final req = chatpb.CreateChatRequest(userId: userId);
      final resp = await _authGuard.execute(() => _client.createChat(req));

      return ChatMapper.fromProto(resp, null);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createChat', e);
      throwGrpcError(e, 'Ошибка открытия чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    Logs().d('ChatRemoteDataSource: getChats');
    try {
      final req = chatpb.GetChatsRequest();
      final resp = await _authGuard.execute(() => _client.getChats(req));

      final users = UserMapper.listFromProto(resp.users);
      final userById = {for (final u in users) int.parse(u.id): u};
      return ChatMapper.listFromProto(resp.chats, userById);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getChats', e);
      throwGrpcError(e, 'Ошибка получения чатов');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
  }) async {
    Logs().d('ChatRemoteDataSource: sendMessage peerUserId=$peerUserId');
    try {
      final req = chatpb.SendMessageRequest(
        peer: commonpb.Peer(userId: Int64(peerUserId)),
        content: content,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));

      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendMessage', e);
      throwGrpcError(e, 'Ошибка отправки сообщения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) async {
    Logs().d('ChatRemoteDataSource: getHistory peerUserId=$peerUserId');
    try {
      final req = chatpb.GetHistoryRequest(
        peer: commonpb.Peer(userId: Int64(peerUserId)),
        messageId: Int64(messageId),
        limit: Int64(limit),
      );
      final resp = await _authGuard.execute(() => _client.getHistory(req));

      return MessageMapper.listFromProto(resp.messages);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getHistory', e);
      throwGrpcError(e, 'Ошибка получения сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getHistory', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }

  @override
  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true}) async {
    if (messageIds.isEmpty) return;
    Logs().d('ChatRemoteDataSource: deleteMessages count=${messageIds.length} forEveryone=$forEveryone');
    try {
      final req = chatpb.DeleteMessagesRequest(
        messageIds: messageIds.map((id) => Int64(id)).toList(),
        revoke: forEveryone,
      );
      await _authGuard.execute(() => _client.deleteMessages(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteMessages', e);
      throwGrpcError(e, 'Ошибка удаления сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }
}
