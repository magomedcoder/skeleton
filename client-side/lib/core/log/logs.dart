import 'package:skeleton/core/log/print_logs_native.dart';

enum Level { debug, info, error, warning, verbose }

class LogEvent {
  final String title;
  final Object? exception;
  final StackTrace? stackTrace;
  final Level level;

  LogEvent(
    this.title, {
    this.exception,
    this.stackTrace,
    this.level = Level.debug,
  });
}

class Logs {
  static final Logs _singleton = Logs._internal();

  static StackTrace? Function(StackTrace?) stackTraceConverter = (s) => s;

  factory Logs() {
    return _singleton;
  }

  Level level = Level.info;
  bool nativeColors = true;

  final List<LogEvent> outputEvents = [];

  Logs._internal();

  void addLogEvent(LogEvent logEvent) {
    outputEvents.add(logEvent);
    //if (logEvent.level.index <= level.index) {
    logEvent.printOut();
    //}
  }

  void d(String title, [Object? exception, StackTrace? stackTrace]) => addLogEvent(
    LogEvent(
      title,
      exception: exception,
      stackTrace: stackTraceConverter(stackTrace),
      level: Level.debug,
    ),
  );

  void i(String title, [Object? exception, StackTrace? stackTrace]) => addLogEvent(
    LogEvent(
      title,
      exception: exception,
      stackTrace: stackTraceConverter(stackTrace),
      level: Level.info,
    ),
  );

  void e(String title, [Object? exception, StackTrace? stackTrace]) => addLogEvent(
    LogEvent(
      title,
      exception: exception,
      stackTrace: stackTraceConverter(stackTrace),
      level: Level.error,
    ),
  );

  void w(String title, [Object? exception, StackTrace? stackTrace]) => addLogEvent(
    LogEvent(
      title,
      exception: exception,
      stackTrace: stackTraceConverter(stackTrace),
      level: Level.warning,
    ),
  );

  void v(String title, [Object? exception, StackTrace? stackTrace]) => addLogEvent(
    LogEvent(
      title,
      exception: exception,
      stackTrace: stackTraceConverter(stackTrace),
      level: Level.verbose,
    ),
  );
}
