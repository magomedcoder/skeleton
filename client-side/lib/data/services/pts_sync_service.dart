import 'dart:async';

import 'package:legion/core/connection_status.dart';
import 'package:legion/core/log/logs.dart';
import 'package:legion/core/reconnect_policy.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/data/data_sources/remote/account_remote_datasource.dart';
import 'package:legion/data/mappers/message_mapper.dart';
import 'package:legion/data/services/user_online_status_service.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/domain/entities/message_deleted_payload.dart';
import 'package:legion/domain/entities/message_read_payload.dart';
import 'package:legion/domain/usecases/chat/get_chats_usecase.dart';
import 'package:legion/generated/grpc_pb/account.pb.dart';
import 'package:legion/generated/grpc_pb/account.pbgrpc.dart' as account_pb;

class PtsSyncService {
  final IAccountRemoteDataSource _accountRemoteDataSource;
  final UserLocalDataSource _userLocalDataSource;
  final GetChatsUseCase _getChatsUseCase;
  final ConnectionStatusService? _connectionStatusService;
  final UserOnlineStatusService? _userOnlineStatusService;
  final ReconnectPolicy _reconnectPolicy;

  StreamSubscription<UpdateResponse>? _updatesSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  bool _isSyncing = false;
  Completer<void>? _initialSyncCompleter;
  Completer<void>? _cycleCompleter;
  bool _running = false;
  int _reconnectAttempt = 0;
  static const int maxPtsDifference = 1000;

  bool _initialStateRetrieved = false;

  final StreamSink<Message>? _newMessageSink;
  final StreamSink<MessageDeletedPayload>? _messageDeletedSink;
  final StreamSink<MessageReadPayload>? _messageReadSink;
  final StreamSink<String>? _taskUpdateSink;

  PtsSyncService(
    this._accountRemoteDataSource,
    this._userLocalDataSource,
    this._getChatsUseCase,
    this._connectionStatusService, {
    UserOnlineStatusService? userOnlineStatusService,
    ReconnectPolicy? reconnectPolicy,
    StreamSink<Message>? newMessageSink,
    StreamSink<MessageDeletedPayload>? messageDeletedSink,
    StreamSink<MessageReadPayload>? messageReadSink,
    StreamSink<String>? taskUpdateSink,
  })  : _userOnlineStatusService = userOnlineStatusService,
        _reconnectPolicy = reconnectPolicy ?? const ReconnectPolicy.hybrid(),
        _newMessageSink = newMessageSink,
        _messageDeletedSink = messageDeletedSink,
        _messageReadSink = messageReadSink,
        _taskUpdateSink = taskUpdateSink;

  Future<void> startSync() async {
    if (_running) {
      Logs().d('PtsSyncService: синхронизация уже запущена');
      return;
    }

    final status = _connectionStatusService?.currentStatus;
    if (status == ConnectionStatus.waitingForNetwork) {
      _connectionStatusService?.setWaitingForNetwork();
      _startListeningForNetwork();
      return;
    }

    _running = true;
    _reconnectAttempt = 0;
    _startListeningForNetwork();

    while (_running) {
      try {
        await _runOneSyncCycle();
      } catch (e, stackTrace) {
        Logs().e('Ошибка цикла синхронизации', e, stackTrace);
        _connectionStatusService?.setDisconnected();
      }

      if (!_running) break;

      final wait = _reconnectPolicy.next(_reconnectAttempt);
      _reconnectAttempt++;
      Logs().i('PtsSyncService: переподключение через ${wait.inMilliseconds} мс (попытка $_reconnectAttempt)');
      await Future.delayed(wait);
    }
  }

  void _startListeningForNetwork() {
    _statusSubscription?.cancel();
    if (_connectionStatusService == null) return;
    _statusSubscription = _connectionStatusService.statusStream.listen((status) {
      if (status != ConnectionStatus.waitingForNetwork && !_running) {
        Logs().i('PtsSyncService: сеть доступна, запуск синхронизации');
        startSync();
      }
    });
  }

  Future<void> _runOneSyncCycle() async {
    _connectionStatusService?.setConnecting();
    _initialSyncCompleter = Completer<void>();
    _cycleCompleter = Completer<void>();

    final updatesStream = _accountRemoteDataSource.getUpdates();

    _updatesSubscription = updatesStream.listen(
      (updateResponse) => _handleUpdateResponse(updateResponse),
      onError: (error, stackTrace) {
        Logs().e('Ошибка в потоке обновлений', error, stackTrace);
        _connectionStatusService?.setDisconnected();
        if (!(_cycleCompleter?.isCompleted ?? true)) {
          _cycleCompleter?.complete();
        }
      },
      onDone: () {
        Logs().i('Поток обновлений завершен');
        _connectionStatusService?.setDisconnected();
        if (!(_cycleCompleter?.isCompleted ?? true)) {
          _cycleCompleter?.complete();
        }
      },
      cancelOnError: false,
    );

    await _cycleCompleter!.future;
  }

  Future<void> _performFullResync() async {
    try {
      final chats = await _getChatsUseCase();
      Logs().i('Загружено ${chats.length} чатов при полной пересинхронизации');
    } catch (e, stackTrace) {
      Logs().e('Ошибка при полной пересинхронизации', e, stackTrace);
      rethrow;
    }
  }

  Future<void> stopSync() async {
    _running = false;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
      _initialSyncCompleter!.completeError(Exception('Синхронизация остановлена'));
    }
    if (_cycleCompleter != null && !_cycleCompleter!.isCompleted) {
      _cycleCompleter!.complete();
    }

    Logs().i('PtsSyncService: синхронизация остановлена');
  }

  Future<void> forceFullSync() async {
    await _userLocalDataSource.clearSyncState();
    _initialStateRetrieved = false;
    await startSync();
  }

  Future<void> _handleUpdateResponse(account_pb.UpdateResponse response) async {
    try {
      if (_isSyncing) return;
      _isSyncing = true;

      if (response.hasState()) {
        final state = response.state;
        final serverPts = state.pts.toInt();
        final serverDate = state.date.toInt();

        if (!_initialStateRetrieved) {
          final localSyncState = await _userLocalDataSource.getSyncState();
          final localPts = localSyncState['pts'] ?? 0;
          Logs().i('Состояние: localPts=$localPts, serverPts=$serverPts, difference=${serverPts - localPts}');
          if (localPts == 0 || serverPts - localPts > maxPtsDifference) {
            Logs().i('Расхождение pts слишком большое (${serverPts - localPts}), полная пересинхронизация');
            await _performFullResync();
          }
          _initialStateRetrieved = true;
        }

        await _userLocalDataSource.setSyncState(serverPts, serverDate);
      }

      for (final update in response.updates) {
        await _processUpdate(update);
      }

      if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
        _initialSyncCompleter!.complete();
        _initialSyncCompleter = null;
      }

      if (response.hasState()) {
        _connectionStatusService?.setConnected();
      }

      _isSyncing = false;
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки обновления', e, stackTrace);
      _isSyncing = false;

      if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
        _initialSyncCompleter!.completeError(e, stackTrace);
      }
    }
  }

  void reset() {
    _initialStateRetrieved = false;
  }

  Future<void> _processUpdate(account_pb.Update update) async {
    try {
      if (update.hasUserStatus()) {
        await _processUserStatus(update.userStatus);
      }

      if (update.hasNewMessage()) {
        await _processNewMessage(update.newMessage);
      }

      if (update.hasNewTask()) {
        await _processNewTask(update.newTask);
      }

      if (update.hasTaskChanged()) {
        await _processTaskChanged(update.taskChanged);
      }

      if (update.hasMessageDeleted()) {
        await _processMessageDeleted(update.messageDeleted);
      }

      if (update.hasMessageRead()) {
        await _processMessageRead(update.messageRead);
      }
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки обновления', e, stackTrace);
    }
  }

  Future<void> _processNewTask(account_pb.UpdateNewTask update) async {
    try {
      if (update.projectId.isEmpty) return;
      _taskUpdateSink?.add(update.projectId);
      Logs().d('PtsSyncService: новая задача в проекте ${update.projectId}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки новой задачи', e, stackTrace);
    }
  }

  Future<void> _processTaskChanged(account_pb.UpdateTaskChanged update) async {
    try {
      if (update.projectId.isEmpty) return;
      _taskUpdateSink?.add(update.projectId);
      Logs().d('PtsSyncService: изменение задачи в проекте ${update.projectId}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки изменения задачи', e, stackTrace);
    }
  }

  Future<void> _processNewMessage(account_pb.UpdateNewMessage update) async {
    try {
      if (!update.hasMessage()) {
        return;
      }

      final message = MessageMapper.fromProto(update.message);
      _newMessageSink?.add(message);
      Logs().d('PtsSyncService: новое сообщение peer=${message.peerUserId} from=${message.fromPeerUserId} id=${message.id}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки нового сообщения', e, stackTrace);
    }
  }

  Future<void> _processMessageDeleted(account_pb.UpdateMessageDeleted update) async {
    try {
      if (update.messageIds.isEmpty) {
        return;
      }

      final payload = MessageDeletedPayload(
        peerId: update.peer.userId.toInt(),
        fromPeerId: update.fromPeer.userId.toInt(),
        messageIds: update.messageIds.map((id) => id.toInt()).toList(),
      );
      _messageDeletedSink?.add(payload);
      Logs().d('PtsSyncService: удаление сообщений peer=${payload.peerId} from=${payload.fromPeerId} ids=${payload.messageIds}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки удаления сообщений', e, stackTrace);
    }
  }

  Future<void> _processMessageRead(UpdateMessageRead update) async {
    try {
      final payload = MessageReadPayload(
        readerUserId: update.readerUserId.toInt(),
        peerUserId: update.peerUserId.toInt(),
        lastReadMessageId: update.lastReadMessageId.toInt(),
      );
      _messageReadSink?.add(payload);
      Logs().d('PtsSyncService: сообщения прочитаны reader=${payload.readerUserId} peer=${payload.peerUserId} upTo=${payload.lastReadMessageId}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки прочтения сообщений', e, stackTrace);
    }
  }

  Future<void> _processUserStatus(account_pb.UpdateUserStatus update) async {
    try {
      final userId = update.userId.toInt().toString();
      final online = update.status;
      _userOnlineStatusService?.setUserOnline(userId, online);
      Logs().d('PtsSyncService: статус пользователя $userId -> ${online ? "онлайн" : "офлайн"}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки статуса пользователя', e, stackTrace);
    }
  }
}
