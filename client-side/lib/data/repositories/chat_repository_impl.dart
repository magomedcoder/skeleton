import 'dart:async';

import 'package:skeleton/core/failures.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/data/data_sources/local/session_model_local_data_source.dart';
import 'package:skeleton/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:skeleton/domain/entities/message.dart';
import 'package:skeleton/domain/entities/session.dart';
import 'package:skeleton/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final IChatRemoteDataSource dataSource;
  final SessionModelLocalDataSource sessionModelLocalDataSource;

  ChatRepositoryImpl(this.dataSource, this.sessionModelLocalDataSource);

  @override
  Future<bool> checkConnection() async {
    try {
      return await dataSource.checkConnection();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка проверки подключения', e);
      throw NetworkFailure('Ошибка проверки подключения');
    }
  }

  @override
  Future<List<String>> getModels() async {
    try {
      return await dataSource.getModels();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка получения моделей', e);
      throw ApiFailure('Ошибка получения списка моделей');
    }
  }

  @override
  Stream<String> sendMessage(
    String sessionId,
    List<Message> messages, {
    String? model,
  }) {
    try {
      return dataSource.sendChatMessage(
        sessionId,
        messages,
        model: model,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка создания потока сообщений', e);
      throw ApiFailure('Ошибка создания потока сообщений');
    }
  }

  @override
  Future<ChatSession> createSession(String title, {String? model}) async {
    try {
      return await dataSource.createSession(title, model: model);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка создания сессии', e);
      throw ApiFailure('Ошибка создания сессии');
    }
  }

  @override
  Future<ChatSession> getSession(String sessionId) async {
    try {
      return await dataSource.getSession(sessionId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка получения сессии', e);
      throw ApiFailure('Ошибка получения сессии');
    }
  }

  @override
  Future<List<ChatSession>> getSessions(int page, int pageSize) async {
    try {
      return await dataSource.getSessions(page, pageSize);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка получения сессий', e);
      throw ApiFailure('Ошибка получения списка сессий');
    }
  }

  @override
  Future<List<Message>> getSessionMessages(
    String sessionId,
    int page,
    int pageSize,
  ) async {
    try {
      return await dataSource.getSessionMessages(sessionId, page, pageSize);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка получения сообщений', e);
      throw ApiFailure('Ошибка получения сообщений сессии');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await dataSource.deleteSession(sessionId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка удаления сессии', e);
      throw ApiFailure('Ошибка удаления сессии');
    }
  }

  @override
  Future<ChatSession> updateSessionTitle(String sessionId, String title) async {
    try {
      return await dataSource.updateSessionTitle(sessionId, title);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка обновления заголовка', e);
      throw ApiFailure('Ошибка обновления заголовка сессии');
    }
  }

  @override
  Future<ChatSession> updateSessionModel(String sessionId, String model) async {
    try {
      return await dataSource.updateSessionModel(sessionId, model);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка обновления модели сессии', e);
      throw ApiFailure('Ошибка обновления модели сессии');
    }
  }

  @override
  Future<String?> getSessionModel(String sessionId) async {
    return sessionModelLocalDataSource.getSessionModel(sessionId);
  }

  @override
  Future<void> setSessionModel(String sessionId, String model) async {
    await sessionModelLocalDataSource.setSessionModel(sessionId, model);
  }
}
