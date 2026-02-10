class Chat {
  final String id;
  final String userId;
  final String userUsername;
  final String userName;
  final String userSurname;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.userId,
    required this.userUsername,
    required this.userName,
    required this.userSurname,
    required this.createdAt,
  });
}
