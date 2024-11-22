/// Log level, that describes the severity of the log message
enum LogLevel implements Comparable<LogLevel> {
  /// {@template traceLevel}
  /// A log level describing events showing step by step execution of your code
  /// that can be ignored during the standard operation,
  /// but may be useful during extended debugging sessions.
  /// {@endtemplate}
  trace._(0),

  /// {@template debugLevel}
  /// A log level used for events considered to be useful during software
  /// debugging when more granular information is needed.
  /// {@endtemplate}
  debug._(1),

  /// {@template infoLevel}
  /// An event happened, the event is purely informative
  /// and can be ignored during normal operations.
  /// {@endtemplate}
  info._(2),

  /// {@template warnLevel}
  /// Unexpected behavior happened inside the application, but it is continuing
  /// its work and the key business features are operating as expected.
  /// {@endtemplate}
  warn._(3),

  /// {@template errorLevel}
  /// One or more functionalities are not working,
  /// preventing some functionalities from working correctly.
  /// For example, a network request failed, a file is missing, etc.
  /// {@endtemplate}
  error._(4),

  /// {@template fatalLevel}
  /// One or more key business functionalities are not working
  /// and the whole system doesn’t fulfill the business functionalities.
  /// {@endtemplate}
  fatal._(5);

  const LogLevel._(this.severity);

  /// The integer value of the log level.
  final int severity;

  @override
  int compareTo(LogLevel other) => severity.compareTo(other.severity);
}
