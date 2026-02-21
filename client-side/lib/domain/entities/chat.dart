class Chat {
  final String id;
  final String userId;
  final String userUsername;
  final String userName;
  final String userSurname;
  final DateTime createdAt;
  final int unreadCount;

  Chat({
    required this.id,
    required this.userId,
    required this.userUsername,
    required this.userName,
    required this.userSurname,
    required this.createdAt,
    this.unreadCount = 0,
  });

  Chat copyWith({int? unreadCount}) {
    return Chat(
      id: id,
      userId: userId,
      userUsername: userUsername,
      userName: userName,
      userSurname: userSurname,
      createdAt: createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
