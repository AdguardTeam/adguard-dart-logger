import 'dart:convert';

import 'package:adguard_logger/src/formatters/logger_base_formatter.dart';
import 'package:adguard_logger/src/model/log_date_time.dart';
import 'package:adguard_logger/src/model/log_level.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/model/log_trace.dart';

/// A custom formatter that serializes [LogRecord] instances into a JSON format
/// suitable for NoSQL storage or structured logging.
///
/// This class also provides functionality to decode a log record from JSON format.
class NoSqlLoggerFormatter extends LoggerBaseFormatter {
  /// Creates an instance of [NoSqlLoggerFormatter].
  /// Since the formatter is stateless, the constructor is marked as `const`.
  const NoSqlLoggerFormatter();

  // JSON keys for serializing log properties
  static const _timeKey = 'time';
  static const _levelKey = 'level';
  static const _traceKey = 'trace';
  static const _messageKey = 'message';
  static const _errorKey = 'error';
  static const _stackTraceKey = 'stackTrace';

  /// Converts a [LogRecord] into a JSON-formatted string.
  ///
  /// This method overrides the base formatter's [format] method to serialize the
  /// record into a JSON string, which can be stored or transmitted for structured logging.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "time": "2024-10-18T12:00:00.000Z",
  ///   "level": "INFO",
  ///   "trace": "TraceID-12345",
  ///   "message": "This is a log message.",
  ///   "error": "Some error message",
  ///   "stackTrace": "StackTrace details"
  /// }
  /// ```
  @override
  String format(LogRecord rec) => formatToStringBuffer(rec, StringBuffer()).toString().trim();

  /// Serializes the [LogRecord] into a [StringBuffer] as a JSON object.
  ///
  /// This method provides a more efficient way to serialize log data by
  /// appending the output to a [StringBuffer]. The buffer can be reused across
  /// multiple logs.
  @override
  StringBuffer formatToStringBuffer(LogRecord rec, StringBuffer sb) => sb
    ..write(
      jsonEncode(
        {
          _timeKey: rec.timeLog.toString(),
          _levelKey: rec.level.name,
          _traceKey: rec.trace.toString(),
          _messageKey: rec.message,
          if (rec.error != null) _errorKey: rec.error.toString(),
          if (rec.stackTrace != null) _stackTraceKey: rec.stackTrace.toString(),
        },
      ),
    );

  /// Decodes a JSON-formatted [Map] back into a [LogRecord].
  ///
  /// This method takes a [Map] (typically from a JSON source) and creates a
  /// corresponding [LogRecord] object, allowing logs to be deserialized back into
  /// Dart objects for further processing.
  ///
  /// Example usage:
  /// ```dart
  /// final Map<String, dynamic> logData = jsonDecode(jsonString);
  /// final logRecord = noSqlLoggerFormatter.decodeFromJson(logData);
  /// ```
  LogRecord decodeFromJson(Map<String, dynamic> data) {
    return LogRecord(
      message: data[_messageKey] as String, // Main log message
      timeLog: LogDateTime(dateTime: DateTime.parse(data[_timeKey] as String)), // Timestamp
      level: LogLevel.values.firstWhere((e) => e.name == data[_levelKey] as String), // Log level
      trace: LogTrace(data[_traceKey] as String), // Trace information
    );
  }
}
