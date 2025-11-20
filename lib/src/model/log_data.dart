/// Represents a base class for logging data.
///
/// This abstract class is used to define various types of data that can be
/// recorded in logs. Each subclass represents a specific type of logging data.
sealed class LoggingData {
  /// An optional string representing a separator.
  final String? separator;

  /// Indicates whether the data should be wrapped in additional characters.
  final bool shouldWrap;

  /// Indicates whether this type of data contains actual information.
  final bool containsData;

  const LoggingData._(this.separator)
      : containsData = true,
        shouldWrap = true;

  /// Factory constructor to create an instance of [_TimeLoggingData].
  /// Marks incoming data as Time parameter of log.
  const factory LoggingData.time() = _TimeLoggingData;

  /// Factory constructor to create an instance of [_LevelLoggingData].
  /// Marks incoming data as Level parameter of log.
  const factory LoggingData.level() = _LevelLoggingData;

  /// Factory constructor to create an instance of [_TraceLoggingData].
  /// Marks incoming data as Trace parameter of log.
  const factory LoggingData.trace() = _TraceLoggingData;

  /// Factory constructor to create an instance of [_MessageLoggingData].
  /// Marks incoming data as Message parameter of log.
  const factory LoggingData.message() = _MessageLoggingData;

  /// Factory constructor to create an instance of [_ErrorLoggingData].
  /// Marks incoming data as Error parameter of log.
  const factory LoggingData.error() = _ErrorLoggingData;

  /// Factory constructor to create an instance of [_StackTraceLoggingData].
  /// Marks incoming data as StackTrace parameter of log.
  const factory LoggingData.stackTrace() = _StackTraceLoggingData;

  /// Factory constructor to create an instance of [_SeparatorLoggingData]
  /// with a specified separator.
  /// Separators are used to separate different types of logging data.
  /// By default, separators are not considered as data.
  const factory LoggingData.separator(String separator) = _SeparatorLoggingData;
}

/// A logging data type representing time information.
final class _TimeLoggingData extends LoggingData {
  const _TimeLoggingData() : super._(null);
}

/// A logging data type representing log level information.
final class _LevelLoggingData extends LoggingData {
  const _LevelLoggingData() : super._(null);
}

/// A logging data type representing trace information.
final class _TraceLoggingData extends LoggingData {
  const _TraceLoggingData() : super._(null);
}

/// A logging data type representing a message.
final class _MessageLoggingData extends LoggingData {
  const _MessageLoggingData() : super._(null);

  @override
  bool get shouldWrap => false;
}

/// A logging data type representing an error.
final class _ErrorLoggingData extends LoggingData {
  const _ErrorLoggingData() : super._(null);

  @override
  bool get shouldWrap => false;
}

/// A logging data type representing a stack trace.
final class _StackTraceLoggingData extends LoggingData {
  const _StackTraceLoggingData() : super._(null);

  @override
  bool get shouldWrap => false;
}

/// A logging data type representing a separator.
final class _SeparatorLoggingData extends LoggingData {
  const _SeparatorLoggingData(String super.separator) : super._();

  @override
  bool get containsData => false;

  @override
  bool get shouldWrap => false;
}
