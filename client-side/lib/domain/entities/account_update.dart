import 'package:legion/domain/entities/message.dart';

sealed class AccountUpdate {}

class UserStatusAccountUpdate extends AccountUpdate {
  final int userId;
  final bool status;

  UserStatusAccountUpdate({
    required this.userId,
    required this.status,
  });
}

class NewMessageAccountUpdate extends AccountUpdate {
  final Message message;

  NewMessageAccountUpdate({required this.message});
}
