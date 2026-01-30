import 'dart:async';

import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';

abstract interface class ChatRepository {
  Future<bool> checkConnection();

  Future<List<String>> getModels();

  Stream<String> sendMessage(
    String sessionId,
    List<Message> messages, {
    String? model,
  });

  Future<ChatSession> createSession(String title);

  Future<ChatSession> getSession(String sessionId);

  Future<List<ChatSession>> getSessions(int page, int pageSize);

  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  );

  Future<void> deleteSession(String sessionId);

  Future<ChatSession> updateSessionTitle(String sessionId, String title);
}
