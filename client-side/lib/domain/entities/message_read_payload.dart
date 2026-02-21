class MessageReadPayload {
  final int readerUserId;
  final int peerUserId;
  final int lastReadMessageId;

  const MessageReadPayload({
    required this.readerUserId,
    required this.peerUserId,
    required this.lastReadMessageId,
  });
}
