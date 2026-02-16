sealed class AccountUpdate {}

class UserStatusAccountUpdate extends AccountUpdate {
  final int userId;
  final bool status;

  UserStatusAccountUpdate({
    required this.userId,
    required this.status,
  });
}
