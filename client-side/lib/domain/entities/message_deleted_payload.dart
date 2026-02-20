class MessageDeletedPayload {
  final int peerId;
  final int fromPeerId;
  final List<int> messageIds;

  const MessageDeletedPayload({
    required this.peerId,
    required this.fromPeerId,
    required this.messageIds,
  });
}
