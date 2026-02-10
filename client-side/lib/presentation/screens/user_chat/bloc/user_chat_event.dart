import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/chat.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatLoadChats extends ChatEvent {
  final int page;
  final int pageSize;

  const ChatLoadChats({this.page = 1, this.pageSize = 50});

  @override
  List<Object?> get props => [page, pageSize];
}

class ChatOpenWithUser extends ChatEvent {
  final String userId;

  const ChatOpenWithUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChatSelectChat extends ChatEvent {
  final Chat chat;

  const ChatSelectChat(this.chat);

  @override
  List<Object?> get props => [chat];
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
