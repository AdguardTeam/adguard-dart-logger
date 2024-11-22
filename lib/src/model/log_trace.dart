import 'package:stack_trace/stack_trace.dart';

/// Represents a log trace, capturing stack trace information.
///
/// This class is used to obtain and store information about the current execution stack,
/// filtering out frames from the `adguard_logger` package by default.
class LogTrace {

  static const _packageName = 'adguard_logger';

  /// The string representation of the trace.
  final String _trace;

  /// Creates a [LogTrace] with a specified trace string.
  const LogTrace(String trace) : _trace = trace;

  /// Captures the current stack trace.
  ///
  /// If [detailed] is set to true, the full location information will be included.
  /// Otherwise, only the member name of the first relevant stack frame is recorded.
  LogTrace.current({bool detailed = false})
      : _trace = _parseStackTrace(
          StackTrace.current,
          detailed,
        );

  /// Parses the current stack trace, filtering out frames from the 'adguard_logger' package.
  ///
  /// If [detailed] is true, includes location details from the stack trace.
  /// Otherwise, only the member name is returned.
  static String _parseStackTrace(StackTrace trace, bool detailed) {
    final frame = Trace.current().frames.firstWhere(
          _checkNotLoggerTrace,
          orElse: () => Trace.current().frames.first,
        );
    var traceToReturn = frame.member ?? '';

    if (detailed || traceToReturn.isEmpty) {
      traceToReturn += ' ${frame.location}';
    }
    return traceToReturn.trim();
  }

  static bool _checkNotLoggerTrace(Frame frame) =>
      frame.package == null ? !frame.library.contains('/$_packageName/') : frame.package != _packageName;

  @override
  String toString() => _trace;
}
