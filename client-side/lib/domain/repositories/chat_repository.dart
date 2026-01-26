import 'dart:async';

import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';

abstract interface class ChatRepository {
  Future<bool> checkConnection();

  Stream<String> sendMessage(String sessionId, List<Message> messages);

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
