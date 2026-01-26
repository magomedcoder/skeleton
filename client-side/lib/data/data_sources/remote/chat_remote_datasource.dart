import 'dart:async';

import 'package:legion/core/failures.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:legion/generated/grpc_pb/chat.pbgrpc.dart' as grpc;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

abstract class IChatRemoteDataSource {
  Future<bool> checkConnection();

  Stream<String> sendChatMessage(
    String sessionId,
    List<Map<String, dynamic>> messages,
  );

  Future<ChatSession> createSession(String title);

  Future<ChatSession> getSession(String sessionId);

  Future<List<ChatSession>> listSessions(int page, int pageSize);

  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  );

  Future<void> deleteSession(String sessionId);

  Future<ChatSession> updateSessionTitle(String sessionId, String title);
}

class ChatRemoteDataSource implements IChatRemoteDataSource {
  final grpc.ChatServiceClient _client;

  ChatRemoteDataSource(this._client);

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _client.checkConnection(
        grpc.Empty(),
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );
      return response.isConnected;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unavailable) {
        return false;
      }
      throw NetworkFailure('Ошибка подключения gRPC: ${e.message}');
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<String> sendChatMessage(
    String sessionId,
    List<Map<String, dynamic>> messages,
  ) async* {
    try {
      final chatMessages = messages.map((msg) {
        final message = grpc.ChatMessage()
          ..id = msg['id'] ?? ''
          ..content = msg['content']
          ..role = msg['role']
          ..createdAt = Int64(msg['created_at'] as int);
        return message;
      }).toList();

      final request = grpc.SendMessageRequest()
        ..sessionId = sessionId
        ..messages.addAll(chatMessages);

      final responseStream = _client.sendMessage(
        request,
        options: CallOptions(timeout: const Duration(seconds: 150)),
      );

      await for (final response in responseStream) {
        if (response.content.isNotEmpty) {
          yield response.content;
        }
        if (response.done) {
          break;
        }
      }
    } on GrpcError catch (e) {
      if (e.code == StatusCode.deadlineExceeded) {
        throw NetworkFailure('Таймаут запроса gRPC');
      }
      throw NetworkFailure('Ошибка gRPC: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка отправки сообщения через gRPC: $e');
    }
  }

  @override
  Future<ChatSession> createSession(String title) async {
    try {
      final request = grpc.CreateSessionRequest()
        ..title = title;

      final response = await _client.createSession(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );

      return ChatSession.fromJson({
        'id': response.id,
        'title': response.title,
        'created_at': response.createdAt.toInt(),
        'updated_at': response.updatedAt.toInt(),
      });
    } on GrpcError catch (e) {
      throw NetworkFailure('Ошибка gRPC при создании сессии: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка создания сессии: $e');
    }
  }

  @override
  Future<ChatSession> getSession(String sessionId) async {
    try {
      final request = grpc.GetSessionRequest()..sessionId = sessionId;

      final response = await _client.getSession(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );

      return ChatSession.fromJson({
        'id': response.id,
        'title': response.title,
        'created_at': response.createdAt.toInt(),
        'updated_at': response.updatedAt.toInt(),
      });
    } on GrpcError catch (e) {
      throw NetworkFailure('Ошибка gRPC при получении сессии: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка получения сессии: $e');
    }
  }

  @override
  Future<List<ChatSession>> listSessions(
    int page,
    int pageSize,
  ) async {
    try {
      final request = grpc.ListSessionsRequest()
        ..page = page
        ..pageSize = pageSize;

      final response = await _client.listSessions(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );

      return response.sessions.map((session) {
        return ChatSession.fromJson({
          'id': session.id,
          'title': session.title,
          'created_at': session.createdAt.toInt(),
          'updated_at': session.updatedAt.toInt(),
        });
      }).toList();
    } on GrpcError catch (e) {
      throw NetworkFailure(
        'Ошибка gRPC при получении списка сессий: ${e.message}',
      );
    } catch (e) {
      throw ApiFailure('Ошибка получения списка сессий: $e');
    }
  }

  @override
  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  ) async {
    try {
      final request = grpc.GetSessionMessagesRequest()
        ..sessionId = sessionId
        ..page = page
        ..pageSize = pageSize;

      final response = await _client.getSessionMessages(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );

      return response.messages.map((msg) {
        return Message(
          id: msg.id,
          content: msg.content,
          role: msg.role == 'user' ? MessageRole.user : MessageRole.assistant,
          createdAt: DateTime.fromMillisecondsSinceEpoch(msg.createdAt.toInt()),
        );
      }).toList();
    } on GrpcError catch (e) {
      throw NetworkFailure('Ошибка gRPC при получении сообщений: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка получения сообщений: $e');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      final request = grpc.DeleteSessionRequest()..sessionId = sessionId;

      await _client.deleteSession(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );
    } on GrpcError catch (e) {
      throw NetworkFailure('Ошибка gRPC при удалении сессии: ${e.message}');
    } catch (e) {
      throw ApiFailure('Ошибка удаления сессии: $e');
    }
  }

  @override
  Future<ChatSession> updateSessionTitle(String sessionId, String title) async {
    try {
      final request = grpc.UpdateSessionTitleRequest()
        ..sessionId = sessionId
        ..title = title;

      final response = await _client.updateSessionTitle(
        request,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );

      return ChatSession.fromJson({
        'id': response.id,
        'title': response.title,
        'created_at': response.createdAt.toInt(),
        'updated_at': response.updatedAt.toInt(),
      });
    } on GrpcError catch (e) {
      throw NetworkFailure(
        'Ошибка gRPC при обновлении заголовка: ${e.message}',
      );
    } catch (e) {
      throw ApiFailure('Ошибка обновления заголовка: $e');
    }
  }
}
