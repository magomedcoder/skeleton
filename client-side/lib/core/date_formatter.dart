extension DateTimeExtension on DateTime {
  int get timestamp => millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
}

extension DateTimeFormatting on DateTime {
  String get formatted => DateFormatter.formatDate(timestamp);

  String get relativeFormatted => DateFormatter.formatRelativeDate(timestamp);

  String get messageFormatted => DateFormatter.formatMessageDate(timestamp);
}

class DateFormatter {

  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * Duration.millisecondsPerSecond,
    );

    return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year} '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  static String formatRelativeDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * Duration.millisecondsPerSecond,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    switch (difference) {
      case 0:
        return 'Сегодня';
      case 1:
        return 'Вчера';
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return '$difference дн. назад';
      default:
        return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';
    }
  }

  static String formatMessageDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * Duration.millisecondsPerSecond,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    switch (difference) {
      case 0:
        return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
      case 1:
        return 'Вчера';
      default:
        return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';
    }
  }

  static bool isToday(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * Duration.millisecondsPerSecond,
    );

    final now = DateTime.now();
    return date.year == now.year
      && date.month == now.month
      && date.day == now.day;
  }

  static bool isYesterday(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * Duration.millisecondsPerSecond,
    );

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    return date.year == yesterday.year
      && date.month == yesterday.month
      && date.day == yesterday.day;
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

class ChatMessageTime {
  ChatMessageTime._();

  static String format(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(msgDay).inDays;

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (diff == 0) {
      return '$hour:$minute';
    }

    if (diff == 1) {
      return 'Вчера $hour:$minute';
    }

    if (diff < 7) {
      return '${_weekday(dateTime)} $hour:$minute';
    }

    return '${dateTime.day}.${dateTime.month}.${dateTime.year} $hour:$minute';
  }

  static String _weekday(DateTime d) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[d.weekday - 1];
  }
}
