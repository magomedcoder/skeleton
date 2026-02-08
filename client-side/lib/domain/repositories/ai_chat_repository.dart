import 'dart:async';

import 'package:legion/domain/entities/ai_message.dart';
import 'package:legion/domain/entities/ai_chat_session.dart';

abstract interface class AIChatRepository {
  Future<bool> checkConnection();

  Future<List<String>> getModels();

  Stream<String> sendMessage(
    String sessionId,
    List<AIMessage> messages, {
    String? model,
  });

  Future<AIChatSession> createSession(String title, {String? model});

  Future<AIChatSession> getSession(String sessionId);

  Future<List<AIChatSession>> getSessions(int page, int pageSize);

  Future<List<AIMessage>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  );

  Future<void> deleteSession(String sessionId);

  Future<AIChatSession> updateSessionTitle(String sessionId, String title);

  Future<AIChatSession> updateSessionModel(String sessionId, String model);

  Future<String?> getSessionModel(String sessionId);

  Future<void> setSessionModel(String sessionId, String model);
}
