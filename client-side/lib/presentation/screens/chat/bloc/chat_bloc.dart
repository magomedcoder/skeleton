import 'dart:async';
import 'dart:typed_data';

import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:legion/domain/usecases/chat/connect_usecase.dart';
import 'package:legion/domain/usecases/chat/create_session_usecase.dart';
import 'package:legion/domain/usecases/chat/delete_session_usecase.dart';
import 'package:legion/domain/usecases/chat/get_models_usecase.dart';
import 'package:legion/domain/usecases/chat/get_session_messages_usecase.dart';
import 'package:legion/domain/usecases/chat/get_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/get_sessions_usecase.dart';
import 'package:legion/domain/usecases/chat/send_message_usecase.dart';
import 'package:legion/domain/usecases/chat/set_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/update_session_model_usecase.dart';
import 'package:legion/domain/usecases/chat/update_session_title_usecase.dart';
import 'package:legion/domain/usecases/runners/get_runners_status_usecase.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/utils/request_logout_on_unauthorized.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_state.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AuthBloc authBloc;
  final ConnectUseCase connectUseCase;
  final GetModelsUseCase getModelsUseCase;
  final GetSessionModelUseCase getSessionModelUseCase;
  final SetSessionModelUseCase setSessionModelUseCase;
  final UpdateSessionModelUseCase updateSessionModelUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final CreateSessionUseCase createSessionUseCase;
  final GetSessionsUseCase getSessionsUseCase;
  final GetSessionMessagesUseCase getSessionMessagesUseCase;
  final DeleteSessionUseCase deleteSessionUseCase;
  final UpdateSessionTitleUseCase updateSessionTitleUseCase;
  final GetRunnersStatusUseCase getRunnersStatusUseCase;

  final _uuid = const Uuid();
  StreamSubscription<String>? _streamSubscription;
  Completer<bool>? _streamCompleter;

  ChatBloc({
    required this.authBloc,
    required this.connectUseCase,
    required this.getModelsUseCase,
    required this.getSessionModelUseCase,
    required this.setSessionModelUseCase,
    required this.updateSessionModelUseCase,
    required this.sendMessageUseCase,
    required this.createSessionUseCase,
    required this.getSessionsUseCase,
    required this.getSessionMessagesUseCase,
    required this.deleteSessionUseCase,
    required this.updateSessionTitleUseCase,
    required this.getRunnersStatusUseCase,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatCreateSession>(_onCreateSession);
    on<ChatLoadSessions>(_onLoadSessions);
    on<ChatSelectSession>(_onSelectSession);
    on<ChatLoadSessionMessages>(_onLoadSessionMessages);
    on<ChatSendMessage>(_onChatSendMessage, transformer: droppable());
    on<ChatClearError>(_onChatClearError);
    on<ChatStopGeneration>(_onChatStopGeneration);
    on<ChatDeleteSession>(_onDeleteSession);
    on<ChatUpdateSessionTitle>(_onUpdateSessionTitle);
    on<ChatLoadModels>(_onLoadModels);
    on<ChatSelectModel>(_onSelectModel);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
) async {
    Logs().i('ChatBloc: старт чата, проверка подключения');
    emit(state.copyWith(isLoading: true));

    try {
      final isConnected = await connectUseCase();
      bool? hasActiveRunners;
      try {
        hasActiveRunners = await getRunnersStatusUseCase();
      } catch (_) {
        hasActiveRunners = null;
      }

      if (isConnected) {
        try {
          final sessionsFuture = getSessionsUseCase(
            page: 1,
            pageSize: 20,
          );
          final modelsFuture = getModelsUseCase();

          final sessions = await sessionsFuture;
          List<String> models = const [];
          String? selectedModel;
          try {
            models = await modelsFuture;
            if (models.isNotEmpty && state.selectedModel == null) {
              selectedModel = models.first;
            }
          } catch (_) {}

          String? currentSessionId;
          List<Message> messages = const [];

          if (sessions.isNotEmpty) {
            currentSessionId = sessions.first.id;

            final sessionMessages = await getSessionMessagesUseCase(
              currentSessionId,
              page: 1,
              pageSize: 50,
            );
            messages = sessionMessages;

            if (selectedModel == null
                && models.isNotEmpty
                && sessions.isNotEmpty) {
              final firstSession = sessions.first;
              if (firstSession.model != null
                  && firstSession.model!.isNotEmpty
                  && models.contains(firstSession.model)) {
                selectedModel = firstSession.model;
              } else {
                try {
                  final savedModel = await getSessionModelUseCase(currentSessionId);
                  if (savedModel != null && models.contains(savedModel)) {
                    selectedModel = savedModel;
                  }
                } catch (_) {}
              }
            }
          }

          emit(
            state.copyWith(
              isConnected: isConnected,
              isLoading: false,
              sessions: sessions,
              currentSessionId: currentSessionId,
              clearCurrentSessionId: sessions.isEmpty,
              messages: messages,
              models: models,
              selectedModel: selectedModel ?? state.selectedModel,
              hasActiveRunners: hasActiveRunners,
              error: null,
            ),
          );
        } catch (e) {
          Logs().e('ChatBloc: ошибка загрузки сессий при старте', e);
          requestLogoutIfUnauthorized(e, authBloc);
          emit(
            state.copyWith(
              isConnected: isConnected,
              isLoading: false,
              hasActiveRunners: hasActiveRunners,
              error: 'Ошибка загрузки сессий',
            ),
          );
        }
      } else {
        Logs().w('ChatBloc: не удалось подключиться к серверу');
        emit(
          state.copyWith(
            isConnected: isConnected,
            isLoading: false,
            hasActiveRunners: hasActiveRunners,
            error: isConnected ? null : 'Не удалось подключиться к серверу',
          ),
        );
      }
    } catch (e) {
      Logs().e('ChatBloc: ошибка подключения при старте', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(
          isConnected: false,
          isLoading: false,
          error: 'Ошибка подключения',
        ),
      );
    }
  }

  Future<void> _onCreateSession(
    ChatCreateSession event,
    Emitter<ChatState> emit,
  ) async {
    Logs().d('ChatBloc: новый чат (сессия будет создана при отправке сообщения)');
    emit(
      state.copyWith(
        currentSessionId: null,
        clearCurrentSessionId: true,
        messages: const [],
        error: null,
      ),
    );
  }

  Future<void> _onLoadSessions(
    ChatLoadSessions event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final sessions = await getSessionsUseCase(
        page: event.page,
        pageSize: event.pageSize,
      );

      emit(state.copyWith(sessions: sessions, isLoading: false, error: null));
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сессий', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(isLoading: false, error: 'Ошибка загрузки сессий'),
      );
    }
  }

  Future<void> _onSelectSession(
    ChatSelectSession event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentSessionId == event.sessionId) {
      return;
    }

    emit(
      state.copyWith(
        currentSessionId: event.sessionId,
        messages: const [],
        isLoading: true,
        error: null,
      ),
    );

    try {
      final messages = await getSessionMessagesUseCase(
        event.sessionId,
        page: 1,
        pageSize: 50,
      );

      String? modelForSession = state.selectedModel;
      if (state.models.isNotEmpty) {
        ChatSession? serverSession;
        for (final s in state.sessions) {
          if (s.id == event.sessionId) {
            serverSession = s;
            break;
          }
        }
        if (serverSession?.model != null
          && serverSession!.model!.isNotEmpty
          && state.models.contains(serverSession.model)) {
          modelForSession = serverSession.model;
        } else {
          try {
            final savedModel =
                await getSessionModelUseCase(event.sessionId);
            if (savedModel != null && state.models.contains(savedModel)) {
              modelForSession = savedModel;
            } else if (modelForSession == null ||
                !state.models.contains(modelForSession)) {
              modelForSession = state.models.first;
            }
          } catch (_) {
            modelForSession ??= state.models.first;
          }
        }
      }

      emit(
        state.copyWith(
          messages: messages,
          isLoading: false,
          selectedModel: modelForSession,
        ),
      );
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений при выборе сессии', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Ошибка загрузки сообщений',
        ),
      );
    }
  }

  Future<void> _onLoadSessionMessages(
    ChatLoadSessionMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final messages = await getSessionMessagesUseCase(
        event.sessionId,
        page: event.page,
        pageSize: event.pageSize,
      );

      final allMessages = [...state.messages, ...messages];

      emit(
        state.copyWith(messages: allMessages, isLoading: false, error: null),
      );
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Ошибка загрузки сообщений',
        ),
      );
    }
  }

  Future<void> _onChatSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    final hasAttachment = event.attachmentFileName != null
        && event.attachmentContent != null
        && event.attachmentContent!.isNotEmpty;
    if (text.isEmpty && !hasAttachment) return;

    await _streamSubscription?.cancel();
    if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
      _streamCompleter!.complete(true);
    }
    _streamSubscription = null;
    _streamCompleter = null;

    String sessionId = state.currentSessionId ?? '';
    final sessionExists = sessionId.isNotEmpty && state.sessions.any((s) => s.id == sessionId);
    if (sessionId.isEmpty || !sessionExists) {
      try {
        final session = await createSessionUseCase(
          model: state.selectedModel ??
              (state.models.isNotEmpty ? state.models.first : null),
        );
        sessionId = session.id;

        final modelToSave = state.selectedModel ??
            (state.models.isNotEmpty ? state.models.first : null);
        if (modelToSave != null) {
          try {
            await setSessionModelUseCase(sessionId, modelToSave);
          } catch (_) {}
        }

        final updatedSessions = [session, ...state.sessions];

        emit(
          state.copyWith(
            currentSessionId: sessionId,
            sessions: updatedSessions,
            messages: const [],
          ),
        );
      } catch (e) {
        Logs().e('ChatBloc: ошибка создания сессии при отправке', e);
        requestLogoutIfUnauthorized(e, authBloc);
        emit(
          state.copyWith(error: 'Ошибка создания сессии', isLoading: false),
        );
        return;
      }
    }

    Logs().d('ChatBloc: отправка сообщения в сессию $sessionId');
    final userMessage = Message(
      id: _uuid.v4(),
      content: text,
      role: MessageRole.user,
      createdAt: DateTime.now(),
      attachmentFileName: event.attachmentFileName,
      attachmentContent: event.attachmentContent != null
        ? Uint8List.fromList(event.attachmentContent!)
        : null,
    );

    final updatedMessages = [...state.messages, userMessage];
    String streamingText = '';

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        isStreaming: true,
        currentStreamingText: '',
        error: null,
      ),
    );

    _streamCompleter = Completer<bool>();

    try {
      final stream = sendMessageUseCase(
        sessionId,
        updatedMessages,
        model: state.selectedModel,
      );

      _streamSubscription = stream.listen(
        (chunk) {
          streamingText += chunk;
          emit(state.copyWith(currentStreamingText: streamingText));
        },
        onDone: () {
          if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
            _streamCompleter!.complete(false);
          }
        },
        onError: (e, st) {
          if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
            _streamCompleter!.completeError(e, st);
          }
        },
        cancelOnError: false,
      );

      final cancelled = await _streamCompleter!.future;

      if (cancelled) {
        return;
      }

      if (streamingText.isNotEmpty) {
        Logs().i('ChatBloc: сообщение получено');
        final assistantMessage = Message(
          id: _uuid.v4(),
          content: streamingText,
          role: MessageRole.assistant,
          createdAt: DateTime.now(),
        );

        final allMessages = [...updatedMessages, assistantMessage];

        emit(
          state.copyWith(
            messages: allMessages,
            isLoading: false,
            isStreaming: false,
            currentStreamingText: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            isStreaming: false,
            currentStreamingText: null,
          ),
        );
      }
    } on Object catch (e) {
      Logs().e('ChatBloc: ошибка отправки сообщения', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(
          isLoading: false,
          isStreaming: false,
          error: 'Ошибка отправки сообщения',
        ),
      );
    } finally {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      _streamCompleter = null;
    }
  }

  Future<void> _onDeleteSession(
    ChatDeleteSession event,
    Emitter<ChatState> emit,
  ) async {
    Logs().d('ChatBloc: удаление сессии ${event.sessionId}');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await deleteSessionUseCase(event.sessionId);

      final updatedSessions = state.sessions
          .where((session) => session.id != event.sessionId)
          .toList();

      final shouldClearCurrent = state.currentSessionId == event.sessionId;

      Logs().i('ChatBloc: сессия удалена');
      emit(
        state.copyWith(
          sessions: updatedSessions,
          currentSessionId: shouldClearCurrent ? null : state.currentSessionId,
          messages: shouldClearCurrent ? const [] : state.messages,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления сессии', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(isLoading: false, error: 'Ошибка удаления сессии'),
      );
    }
  }

  Future<void> _onUpdateSessionTitle(
    ChatUpdateSessionTitle event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final updatedSession = await updateSessionTitleUseCase(
        event.sessionId,
        event.title,
      );

      final updatedSessions = state.sessions.map((session) {
        if (session.id == event.sessionId) {
          return updatedSession;
        }
        return session;
      }).toList();

      emit(
        state.copyWith(
          sessions: updatedSessions,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      Logs().e('ChatBloc: ошибка обновления заголовка', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Ошибка обновления заголовка',
        ),
      );
    }
  }

  Future<void> _onLoadModels(
    ChatLoadModels event,
    Emitter<ChatState> emit,
  ) async {
    Logs().d('ChatBloc: загрузка списка моделей');
    try {
      final models = await getModelsUseCase();
      String? selectedModel = state.selectedModel;
      if (models.isNotEmpty && selectedModel == null) {
        selectedModel = models.first;
      }
      if (models.isNotEmpty
        && selectedModel != null
        && !models.contains(selectedModel)) {
        selectedModel = models.first;
      }
      emit(
        state.copyWith(
          models: models,
          selectedModel: selectedModel ?? state.selectedModel,
        ),
      );
    } catch (e) {
      Logs().w('ChatBloc: ошибка загрузки моделей', e);
    }
  }

  Future<void> _onSelectModel(
    ChatSelectModel event,
    Emitter<ChatState> emit,
  ) async {
    final sessionId = state.currentSessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      try {
        await updateSessionModelUseCase(sessionId, event.model);
      } catch (_) {}
      try {
        await setSessionModelUseCase(sessionId, event.model);
      } catch (_) {}
    }
    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return ChatSession(
          id: s.id,
          title: s.title,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          model: event.model,
        );
      }
      return s;
    }).toList();
    emit(state.copyWith(
      selectedModel: event.model,
      sessions: updatedSessions,
    ));
  }

  void _onChatClearError(ChatClearError event, Emitter<ChatState> emit) {
    emit(state.copyWith(error: null));
  }

  Future<void> _onChatStopGeneration(
    ChatStopGeneration event,
    Emitter<ChatState> emit,
  ) async {
    Logs().d('ChatBloc: остановка генерации');
    await _streamSubscription?.cancel();
    if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
      _streamCompleter!.complete(true);
    }
    _streamSubscription = null;
    _streamCompleter = null;

    if (state.currentStreamingText != null
        && state.currentStreamingText!.isNotEmpty) {
      final assistantMessage = Message(
        id: _uuid.v4(),
        content: state.currentStreamingText!,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      );

      final allMessages = [...state.messages, assistantMessage];

      emit(
        state.copyWith(
          messages: allMessages,
          isLoading: false,
          isStreaming: false,
          currentStreamingText: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: false,
          isStreaming: false,
          currentStreamingText: null,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
      _streamCompleter!.complete(true);
    }
    return super.close();
  }
}
