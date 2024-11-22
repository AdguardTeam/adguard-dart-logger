import 'dart:async';

import 'package:adguard_logger/src/model/log_date_time.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/model/log_trace.dart';
import 'package:adguard_logger/src/extensions/http_logger_extension.dart';
import 'package:adguard_logger/src/model/log_level.dart';

/// Getter for the default logger instance.
/// If no logger is available in the current zone, it creates a new one with a set of default extensions.
BaseLogger get logger => Zone.current[Logger.loggerKey] as BaseLogger? ?? Logger();

/// Abstract class for a logger that can be extended with custom loggers.
/// Contains methods for logging messages at different levels.
abstract class BaseLogger {
  /// Logger messages stream.
  abstract final Stream<LogRecord> logStream;

  /// The minimum log level that will be listened to.
  abstract LogLevel listenableLevel;

  /// Returns an extension of a specific type [T] if available.
  /// Extensions are provides specific ways to retrieve information to a logger.
  /// For example, see [HttpLoggerExtension], that logs HTTP requests and responses.
  T? extension<T extends LoggerExtension<dynamic>>();

  /// Destroys the logger, cleaning up any resources.
  void destroy();

  /// Logs a message at a given [level].
  /// Logged messages are passing to specific [appenders] for further output,
  /// for example, [ConsoleLogAppender] outputs logs to the console.
  /// For more information, see [BaseLogAppender].
  void log(
    String message, {
    required LogLevel level,
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  });

  /// {@template logInfo}
  /// Logs an informational message with [LogLevel.info].
  /// {@macro infoLevel}
  /// {@endtemplate}
  void logInfo(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.info,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@template logDebug}
  /// Logs an informational message with [LogLevel.info].
  /// {@macro debugLevel}
  /// {@endtemplate}
  void logDebug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.debug,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@template logTrace}
  /// Logs an informational message with [LogLevel.trace].
  /// {@macro traceLevel}
  /// {@endtemplate}
  void logTrace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.trace,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@template logError}
  /// Logs an informational message with [LogLevel.error].
  /// {@macro errorLevel}
  /// {@endtemplate}
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@template logFatal}
  /// Logs an informational message with [LogLevel.fatal].
  /// {@macro fatalLevel}
  /// {@endtemplate}
  void logFatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.fatal,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@template logWarning}
  /// Logs an informational message with [LogLevel.fatal].
  /// {@macro warnLevel}
  /// {@endtemplate}
  void logWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      log(
        message,
        level: LogLevel.warn,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );
}

/// Default logger implementation, which allows for extensibility via [LoggerExtension].
/// Uses a stream-based system to handle log records.
class Logger extends BaseLogger {
  static const loggerKey = 'adguard_logger';

  final StreamController<LogRecord> _logStreamController = StreamController.broadcast();
  late final Map<Object, LoggerExtension<dynamic>> _extensions;

  @override
  LogLevel listenableLevel;

  @override
  late final Stream<LogRecord> logStream;

  /// Constructor for [Logger].
  /// Takes an optional [listenableLevel] to set the minimum log level that will be listened to.
  /// Optionally, it also accepts a list of [LoggerExtension]s to extend retrieve info functionality.
  /// See [LoggerExtension] for more information.
  Logger({
    this.listenableLevel = LogLevel.info,
    Iterable<LoggerExtension<dynamic>> extensions = const [],
  }) {
    _extensions = _initializeExtensions(extensions);
    logStream = _logStreamController.stream.where((record) => record.level.compareTo(listenableLevel) >= 0);
  }

  @override
  void log(
    String message, {
    required LogLevel level,
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) {
    _logStreamController.add(LogRecord(
      message: message,
      level: level,
      timeLog: timeLog ?? LogDateTime(dateTime: DateTime.now()),
      trace: trace ?? LogTrace.current(),
      stackTrace: stackTrace,
      error: error,
    ));
  }

  /// Maps logger extensions from an iterable to a [Map] for faster access.
  Map<Object, LoggerExtension<dynamic>> _initializeExtensions(Iterable<LoggerExtension<dynamic>> extensionsIterable) {
    return Map<Object, LoggerExtension<dynamic>>.unmodifiable(
      {
        for (final extension in extensionsIterable) extension.type: extension.._logger = this,
      },
    );
  }

  @override
  T? extension<T extends LoggerExtension<dynamic>>() => _extensions[T] as T?;

  @override
  void destroy() => _logStreamController.close();
}

/// Abstract class for logger extensions, enabling modularity in logging.
/// Each extension is tied to a logger and can log messages using the logger.
abstract class LoggerExtension<T extends LoggerExtension<T>> {
  Object get type => T;

  late final BaseLogger _logger;

  /// {@macro logInfo}
  /// {@macro infoLevel}
  void logInfo(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      _logger.logInfo(
        message,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@macro logDebug}
  /// {@macro debugLevel}
  void logDebug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      _logger.logDebug(
        message,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@macro logError}
  /// {@macro errorLevel}
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      _logger.logError(
        message,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@macro logFatal}
  /// {@macro fatalLevel}
  void logFatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      _logger.logFatal(
        message,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );

  /// {@macro logTrace}
  /// {@macro traceLevel}
  void logTrace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogDateTime? timeLog,
    LogTrace? trace,
  }) =>
      _logger.logTrace(
        message,
        error: error,
        stackTrace: stackTrace,
        timeLog: timeLog,
        trace: trace,
      );
}
