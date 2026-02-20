import 'package:equatable/equatable.dart';
import 'package:legion/domain/entities/chat.dart';
import 'package:legion/domain/entities/message.dart';

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

class ChatBackToList extends ChatEvent {
  const ChatBackToList();
}

class ChatNewMessageReceived extends ChatEvent {
  final Message message;

  const ChatNewMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatDeleteMessage extends ChatEvent {
  final Message message;
  final bool forEveryone;

  const ChatDeleteMessage(this.message, {this.forEveryone = true});

  @override
  List<Object?> get props => [message, forEveryone];
}

class ChatToggleMessageSelection extends ChatEvent {
  final Message message;

  const ChatToggleMessageSelection(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatDeleteSelectedMessages extends ChatEvent {
  final bool forEveryone;

  const ChatDeleteSelectedMessages({this.forEveryone = true});

  @override
  List<Object?> get props => [forEveryone];
}

class ChatClearSelection extends ChatEvent {
  const ChatClearSelection();
}

class ChatSelectAllMyMessages extends ChatEvent {
  const ChatSelectAllMyMessages();
}
