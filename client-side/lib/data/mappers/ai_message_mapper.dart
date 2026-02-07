import 'package:fixnum/fixnum.dart';
import 'package:skeleton/domain/entities/ai_message.dart';
import 'package:skeleton/generated/grpc_pb/aichat.pb.dart' as grpc;

abstract class AIMessageMapper {
  AIMessageMapper._();

  static DateTime _dateTimeFromUnixSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static int _dateTimeToUnixSeconds(DateTime dt) {
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  static AIMessageRole _roleFromProto(String role) {
    switch (role) {
      case 'user':
        return AIMessageRole.user;
      case 'assistant':
        return AIMessageRole.assistant;
      default:
        return AIMessageRole.user;
    }
  }

  static String _roleToProto(AIMessageRole role) {
    return role == AIMessageRole.user ? 'user' : 'assistant';
  }

  static AIMessage fromProto(grpc.ChatMessage proto) {
    return AIMessage(
      id: proto.id,
      content: proto.content,
      role: _roleFromProto(proto.role),
      createdAt: _dateTimeFromUnixSeconds(proto.createdAt.toInt()),
      attachmentFileName: proto.hasAttachmentName()
        ? proto.attachmentName
        : null,
    );
  }

  static grpc.ChatMessage toProto(AIMessage entity) {
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

  static List<AIMessage> listFromProto(List<grpc.ChatMessage> protos) {
    return protos.map(fromProto).toList();
  }

  static List<grpc.ChatMessage> listToProto(List<AIMessage> entities) {
    return entities.map(toProto).toList();
  }
}
