import 'package:adguard_logger/src/model/log_data.dart';
import 'package:adguard_logger/src/model/log_date_time.dart';
import 'package:adguard_logger/src/model/log_level.dart';
import 'package:adguard_logger/src/model/log_trace.dart';

/// Represents a single log record.
///
/// This class encapsulates all the information related to a specific log entry,
/// including the message, timestamp, log level, trace information, error details,
/// and associated stack trace.
class LogRecord {
  /// The log message.
  final String message;

  /// The timestamp of when the log was created.
  final LogDateTime timeLog;

  /// The severity level of the log.
  final LogLevel level;

  /// The trace information associated with the log.
  final LogTrace trace;

  /// An optional list of additional tags associated with the log.
  final List<String>? additionalTags;

  /// An optional error object associated with the log.
  final Object? error;

  /// An optional stack trace associated with the log.
  final StackTrace? stackTrace;

  /// Creates a new instance of [LogRecord].
  ///
  /// The [message], [timeLog], [level], and [trace] parameters are required,
  /// while [error] and [stackTrace] are optional.
  LogRecord({
    required this.message,
    required this.timeLog,
    required this.level,
    required this.trace,
    this.additionalTags,
    this.error,
    this.stackTrace,
  });

  /// Converts the log record into a map representation.
  ///
  /// The map keys are of type [LoggingData], representing the type of log data,
  /// and the values are the corresponding string representations.
  Map<LoggingData, String> get asMap => {
        const LoggingData.message(): message,
        const LoggingData.level(): level.name,
        const LoggingData.time(): timeLog.toString(),
        const LoggingData.trace(): trace.toString(),
        if (error != null) const LoggingData.error(): error.toString(),
        if (stackTrace != null) const LoggingData.stackTrace(): stackTrace.toString(),
      };
}
