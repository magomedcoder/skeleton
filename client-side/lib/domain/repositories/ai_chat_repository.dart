import 'dart:async';

import 'package:skeleton/domain/entities/message.dart';
import 'package:skeleton/domain/entities/session.dart';

abstract interface class AIChatRepository {
  Future<bool> checkConnection();

  Future<List<String>> getModels();

  Stream<String> sendMessage(
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

  Future<String?> getSessionModel(String sessionId);

  Future<void> setSessionModel(String sessionId, String model);
}
