import 'package:intl/intl.dart';

/// Represents a formatted date and time for logging.
///
/// This class provides a way to store a [DateTime] object along with an optional
/// [DateFormat] to format the date and time as a string.
class LogDateTime {
  /// The date and time to be logged.
  final DateTime dateTime;

  /// An optional formatter for the date and time.
  final DateFormat? format;

  /// Creates a new instance of [LogDateTime].
  ///
  /// The [dateTime] parameter is required, while [format] is optional.
  const LogDateTime({
    required this.dateTime,
    this.format,
  });

  @override
  String toString() => format == null ? dateTime.toIso8601String() : format!.format(dateTime);
}
