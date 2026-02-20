class Message {
  final int id;
  final int peerUserId;
  final int fromPeerUserId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.peerUserId,
    required this.fromPeerUserId,
    required this.content,
    required this.createdAt,
  });

  int get senderId => fromPeerUserId;

  bool isInDialog(int myUserId, int otherUserId) {
    return (peerUserId == myUserId && fromPeerUserId == otherUserId) || (peerUserId == otherUserId && fromPeerUserId == myUserId);
  }
}
