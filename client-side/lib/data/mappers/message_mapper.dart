import 'package:fixnum/fixnum.dart';
import 'package:legion/domain/entities/message.dart';
import 'package:legion/generated/grpc_pb/chat.pb.dart' as grpc;

abstract class MessageMapper {
  MessageMapper._();

  static DateTime _dateTimeFromUnixSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static int _dateTimeToUnixSeconds(DateTime dt) {
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  static MessageRole _roleFromProto(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        return MessageRole.user;
    }
  }

  static String _roleToProto(MessageRole role) {
    return role == MessageRole.user ? 'user' : 'assistant';
  }

  static Message fromProto(grpc.ChatMessage proto) {
    return Message(
      id: proto.id,
      content: proto.content,
      role: _roleFromProto(proto.role),
      createdAt: _dateTimeFromUnixSeconds(proto.createdAt.toInt()),
      attachmentFileName: proto.hasAttachmentName()
        ? proto.attachmentName
        : null,
    );
  }

  static grpc.ChatMessage toProto(Message entity) {
    final p = grpc.ChatMessage();
    p.id = entity.id;
    p.content = entity.content;
    p.role = _roleToProto(entity.role);
    p.createdAt = Int64(_dateTimeToUnixSeconds(entity.createdAt));
    if (entity.attachmentFileName != null && entity.attachmentFileName!.isNotEmpty) {
      p.attachmentName = entity.attachmentFileName!;
    }

    if (entity.attachmentContent != null && entity.attachmentContent!.isNotEmpty) {
      p.attachmentContent = entity.attachmentContent!;
    }

    return p;
  }

  static List<Message> listFromProto(List<grpc.ChatMessage> protos) {
    return protos.map(fromProto).toList();
  }

  static List<grpc.ChatMessage> listToProto(List<Message> entities) {
    return entities.map(toProto).toList();
  }
}
