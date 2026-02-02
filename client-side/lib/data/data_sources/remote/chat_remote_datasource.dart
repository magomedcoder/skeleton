import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:legion/core/auth_guard.dart';
import 'package:legion/core/failures.dart';
import 'package:legion/core/grpc_channel_manager.dart';
import 'package:legion/core/grpc_error_handler.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/data/mappers/message_mapper.dart';
import 'package:legion/data/mappers/session_mapper.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as grpc;

abstract class IChatRemoteDataSource {
  Future<bool> checkConnection();

  Future<List<String>> getModels();

  Stream<String> sendChatMessage(
    String sessionId,
    List<Message> messages, {
    String? model,
  });

  Future<ChatSession> createSession(String title, {String? model});

  Future<ChatSession> getSession(String sessionId);

  Future<List<ChatSession>> getSessions(int page, int pageSize);

  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  );

  Future<void> deleteSession(String sessionId);

  Future<ChatSession> updateSessionTitle(String sessionId, String title);

  Future<ChatSession> updateSessionModel(String sessionId, String model);
}

class ChatRemoteDataSource implements IChatRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ChatRemoteDataSource(this._channelManager, this._authGuard);

  grpc.ChatServiceClient get _client => _channelManager.chatClient;

  @override
  Future<bool> checkConnection() async {
    Logs().d('ChatRemoteDataSource: проверка подключения');
    try {
      final response = await _client.checkConnection(grpc.Empty());
      Logs().i('ChatRemoteDataSource: подключение ${response.isConnected ? "установлено" : "нет"}');
      return response.isConnected;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        Logs().w('ChatRemoteDataSource: сервер недоступен');
        return false;
      }
      Logs().e('ChatRemoteDataSource: ошибка проверки подключения', e);
      throw NetworkFailure('Ошибка подключения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка проверки подключения', e);
      return false;
    }
  }

  @override
  Future<List<String>> getModels() async {
    Logs().d('ChatRemoteDataSource: получение списка моделей');
    try {
      final response = await _client.getModels(grpc.Empty());
      Logs().i('ChatRemoteDataSource: получено моделей: ${response.models.length}');
      return response.models;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        Logs().w('ChatRemoteDataSource: сервер недоступен при получении моделей');
        throw NetworkFailure('Ошибка подключения');
      }
      Logs().e('ChatRemoteDataSource: ошибка получения моделей', e);
      throw NetworkFailure('Ошибка получения списка моделей');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения моделей', e);
      throw ApiFailure('Ошибка получения списка моделей');
    }
  }

  @override
  Stream<String> sendChatMessage(
    String sessionId,
    List<Message> messages, {
    String? model,
  }) async* {
    Logs().d('ChatRemoteDataSource: отправка сообщения в сессию $sessionId');
    try {
      final chatMessages = MessageMapper.listToProto(messages);

      final request = grpc.SendMessageRequest()
        ..sessionId = sessionId
        ..messages.addAll(chatMessages);
      if (model != null && model.isNotEmpty) {
        request.model = model;
      }

      final responseStream = _client.sendMessage(request);

      await for (final response in responseStream) {
        if (response.content.isNotEmpty) {
          yield response.content;
        }

        if (response.done) {
          break;
        }
      }
      Logs().i('ChatRemoteDataSource: сообщение отправлено');
    } on GrpcError catch (e) {
      if (e.code == StatusCode.deadlineExceeded) {
        Logs().w('ChatRemoteDataSource: таймаут отправки сообщения');
        throw NetworkFailure('Превышено время ожидания');
      }
      Logs().e('ChatRemoteDataSource: ошибка отправки сообщения', e);
      throwGrpcError(e, 'Ошибка отправки сообщения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка отправки сообщения', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<ChatSession> createSession(String title, {String? model}) async {
    Logs().d('ChatRemoteDataSource: создание сессии "$title"');
    try {
      final request = grpc.CreateSessionRequest(
        title: title,
      );
      if (model != null && model.isNotEmpty) {
        request.model = model;
      }

      final response = await _authGuard.execute(
        () => _client.createSession(request),
      );
      Logs().i('ChatRemoteDataSource: сессия создана');
      return SessionMapper.fromProto(response);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка создания сессии', e);
      throwGrpcError(e, 'Ошибка создания сессии');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка создания сессии', e);
      throw ApiFailure('Ошибка создания сессии');
    }
  }

  @override
  Future<ChatSession> getSession(String sessionId) async {
    Logs().v('ChatRemoteDataSource: получение сессии $sessionId');
    try {
      final request = grpc.GetSessionRequest(
        sessionId: sessionId
      );

      final response = await _authGuard.execute(
        () => _client.getSession(request),
      );
      return SessionMapper.fromProto(response);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сессии', e);
      throwGrpcError(e, 'Ошибка получения сессии');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сессии', e);
      throw ApiFailure('Ошибка получения сессии');
    }
  }

  @override
  Future<List<ChatSession>> getSessions(
    int page,
    int pageSize,
  ) async {
    Logs().d('ChatRemoteDataSource: получение сессий page=$page pageSize=$pageSize');
    try {
      final request = grpc.GetSessionsRequest(
        page: page,
        pageSize: pageSize,
      );

      final response = await _authGuard.execute(
        () => _client.getSessions(request),
      );
      final sessions = SessionMapper.listFromProto(response.sessions);
      Logs().i('ChatRemoteDataSource: получено сессий: ${sessions.length}');
      return sessions;
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сессий', e);
      throwGrpcError(e, 'Ошибка получения списка сессий');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сессий', e);
      throw ApiFailure('Ошибка получения списка сессий');
    }
  }

  @override
  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  ) async {
    Logs().v('ChatRemoteDataSource: получение сообщений сессии $sessionId');
    try {
      final request = grpc.GetSessionMessagesRequest(
        sessionId: sessionId,
        page: page,
        pageSize: pageSize,
      );

      final response = await _authGuard.execute(
        () => _client.getSessionMessages(request),
      );
      return MessageMapper.listFromProto(response.messages);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сообщений', e);
      throwGrpcError(e, 'Ошибка получения сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка получения сообщений', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    Logs().d('ChatRemoteDataSource: удаление сессии $sessionId');
    try {
      final request = grpc.DeleteSessionRequest(
        sessionId: sessionId
      );

      await _authGuard.execute(() => _client.deleteSession(request));
      Logs().i('ChatRemoteDataSource: сессия удалена');
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка удаления сессии', e);
      throwGrpcError(e, 'Ошибка удаления сессии');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка удаления сессии', e);
      throw ApiFailure('Ошибка удаления сессии');
    }
  }

  @override
  Future<ChatSession> updateSessionTitle(String sessionId, String title) async {
    Logs().d('ChatRemoteDataSource: обновление заголовка сессии $sessionId');
    try {
      final request = grpc.UpdateSessionTitleRequest(
        sessionId: sessionId,
        title: title,
      );

      final response = await _authGuard.execute(
        () => _client.updateSessionTitle(request),
      );
      Logs().i('ChatRemoteDataSource: заголовок обновлён');
      return SessionMapper.fromProto(response);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка обновления заголовка', e);
      throwGrpcError(e, 'Ошибка обновления заголовка');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка обновления заголовка', e);
      throw ApiFailure('Ошибка обновления заголовка');
    }
  }

  @override
  Future<ChatSession> updateSessionModel(String sessionId, String model) async {
    Logs().d('ChatRemoteDataSource: обновление модели сессии $sessionId');
    try {
      final request = grpc.UpdateSessionModelRequest(
        sessionId: sessionId,
        model: model,
      );

      final response = await _authGuard.execute(
        () => _client.updateSessionModel(request),
      );
      Logs().i('ChatRemoteDataSource: модель сессии обновлена');
      return SessionMapper.fromProto(response);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка обновления модели сессии', e);
      throwGrpcError(e, 'Ошибка обновления модели сессии');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка обновления модели сессии', e);
      throw ApiFailure('Ошибка обновления модели сессии');
    }
  }
}
