import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatCreateSession extends ChatEvent {
  final String? title;

  const ChatCreateSession({this.title});

  @override
  List<Object?> get props => [title];
}

class ChatLoadSessions extends ChatEvent {
  final int page;
  final int pageSize;

  const ChatLoadSessions({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

class ChatSelectSession extends ChatEvent {
  final String sessionId;

  const ChatSelectSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ChatLoadSessionMessages extends ChatEvent {
  final String sessionId;
  final int page;
  final int pageSize;

  const ChatLoadSessionMessages(
    this.sessionId, {
    this.page = 1,
    this.pageSize = 50,
  });

  @override
  List<Object?> get props => [sessionId, page, pageSize];
}

class ChatSendMessage extends ChatEvent {
  final String text;

  const ChatSendMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class ChatClearError extends ChatEvent {
  const ChatClearError();
}

class ChatStopGeneration extends ChatEvent {
  const ChatStopGeneration();
}

class ChatDeleteSession extends ChatEvent {
  final String sessionId;

  const ChatDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ChatUpdateSessionTitle extends ChatEvent {
  final String sessionId;
  final String title;

  const ChatUpdateSessionTitle(this.sessionId, this.title);

  @override
  List<Object?> get props => [sessionId, title];
}
