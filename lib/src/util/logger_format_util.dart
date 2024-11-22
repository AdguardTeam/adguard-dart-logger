import 'package:intl/intl.dart';

/// Utility class for handling logger-specific formatting tasks.
/// This class provides predefined formats for log timestamps.
abstract class LoggerFormatUtil {
  /// The default format used for logging timestamps.
  /// This format represents date and time down to milliseconds: `yyyy-MM-dd HH:mm:ss.SSS`.
  static const logFormat = 'yyyy-MM-dd HH:mm:ss.SSS';

  /// Provides the default [DateFormat] object, initialized with the [logFormat].
  ///
  /// This can be used to format timestamps consistently throughout the logging system.
  /// Example usage:
  /// ```dart
  /// final formattedTime = LoggerFormatUtil.defaultTimeFormat.format(DateTime.now());
  /// ```
  static DateFormat get defaultTimeFormat => DateFormat(logFormat);
}
