import 'package:adguard_logger/src/model/log_record.dart';

/// An abstract base class for formatting log records.
///
/// This class provides a structure for creating different log formatters
/// that can format log records into string representations. Implementing
/// classes must define how to format a [LogRecord] into a [StringBuffer].
abstract class LoggerBaseFormatter {
  const LoggerBaseFormatter();

  /// Writes the formatted output of [rec] into the provided [StringBuffer].
  ///
  /// This method must be implemented by subclasses to specify how a log
  /// record is formatted. The formatted output is appended to [sb].
  ///
  /// [rec] is the log record to format.
  /// [sb] is the [StringBuffer] to write the formatted output into.
  StringBuffer formatToStringBuffer(LogRecord rec, StringBuffer sb);

  /// Formats a log record into a string.
  ///
  /// This method calls [formatToStringBuffer] to perform the actual
  /// formatting and returns the formatted log as a [String].
  String format(LogRecord rec) => formatToStringBuffer(rec, StringBuffer()).toString();
}
