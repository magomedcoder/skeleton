import 'package:equatable/equatable.dart';

abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends AIChatEvent {
  const ChatStarted();
}

class ChatCreateSession extends AIChatEvent {
  final String? title;

  const ChatCreateSession({this.title});

  @override
  List<Object?> get props => [title];
}

class ChatLoadSessions extends AIChatEvent {
  final int page;
  final int pageSize;

  const ChatLoadSessions({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

class ChatSelectSession extends AIChatEvent {
  final String sessionId;

  const ChatSelectSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ChatLoadSessionMessages extends AIChatEvent {
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

class ChatSendMessage extends AIChatEvent {
  final String text;
  final String? attachmentFileName;
  final List<int>? attachmentContent;

  const ChatSendMessage(
    this.text, {
    this.attachmentFileName,
    this.attachmentContent,
  });

  @override
  List<Object?> get props => [text, attachmentFileName];
}

class ChatClearError extends AIChatEvent {
  const ChatClearError();
}

class ChatStopGeneration extends AIChatEvent {
  const ChatStopGeneration();
}

class ChatLoadModels extends AIChatEvent {
  const ChatLoadModels();
}

class ChatSelectModel extends AIChatEvent {
  final String model;

  const ChatSelectModel(this.model);

  @override
  List<Object?> get props => [model];
}

class ChatDeleteSession extends AIChatEvent {
  final String sessionId;

  const ChatDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ChatUpdateSessionTitle extends AIChatEvent {
  final String sessionId;
  final String title;

  const ChatUpdateSessionTitle(this.sessionId, this.title);

  @override
  List<Object?> get props => [sessionId, title];
}
