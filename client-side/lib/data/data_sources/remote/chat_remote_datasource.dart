import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/chat_mapper.dart';
import 'package:legion/data/mappers/message_mapper.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;

abstract class IChatRemoteDataSource {
  Future<Chat> createChat(String userId);

  Future<List<Chat>> getChats({required int page, required int pageSize});

  Future<Message> sendMessage({
    required String chatId,
    required String content,
  });

  Future<List<Message>> getMessages({
    required String chatId,
    required int page,
    required int pageSize,
  });
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

      return ChatMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createChat', e);
      throwGrpcError(e, 'Ошибка открытия чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<List<Chat>> getChats({
    required int page,
    required int pageSize,
  }) async {
    Logs().d('ChatRemoteDataSource: getChats page=$page');
    try {
      final req = chatpb.GetChatsRequest(page: page, pageSize: pageSize);
      final resp = await _authGuard.execute(() => _client.getChats(req));

      return ChatMapper.listFromProto(resp.chats);
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
    required String chatId,
    required String content,
  }) async {
    Logs().d('ChatRemoteDataSource: sendMessage chatId=$chatId');
    try {
      final req = chatpb.SendMessageRequest(chatId: chatId, content: content);
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
  Future<List<Message>> getMessages({
    required String chatId,
    required int page,
    required int pageSize,
  }) async {
    Logs().d('ChatRemoteDataSource: getMessages chatId=$chatId');
    try {
      final req = chatpb.GetMessagesRequest(
        chatId: chatId,
        page: page,
        pageSize: pageSize,
      );
      final resp = await _authGuard.execute(() => _client.getMessages(req));

      return MessageMapper.listFromProto(resp.messages);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getMessages', e);
      throwGrpcError(e, 'Ошибка получения сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getMessages', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }
}
