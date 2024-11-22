import 'dart:async';

import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/logger.dart';
import 'package:meta/meta.dart';

/// Abstract base class for log appenders, responsible for handling subscriptions
/// to specific loggers and managing log records.
///
/// A log appender listens to a logger's log stream and processes the log records
/// it receives. It also provides methods to manage the subscriptions and clean up resources.
abstract class BaseLogAppender {
  /// A list of active subscriptions to log streams from different loggers.
  /// The subscriptions are stored here to allow easy cancellation when no longer needed.
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  /// Processes a single [LogRecord].
  /// This method must be implemented by subclasses to define how the log record is handled.
  /// It can perform operations like formatting and outputting the log to a console, file, or other destinations.
  @protected
  FutureOr<void> handle(LogRecord record);

  /// Attaches this log appender to a [logger], subscribing to its log stream.
  /// The log records are listened to and handled asynchronously using the [handle] method.
  ///
  /// - [logger]: The logger to attach this appender to.
  void attachToLogger(BaseLogger logger) => _subscriptions.add(
        logger.logStream.listen(
          (event) async => await handle(event),
        ),
      );

  /// Detaches the log appender from all subscribed loggers by canceling
  /// all active subscriptions.
  Future<void> detachFromLoggers() => _cancelSubscriptions();

  /// Allows calling the log appender directly with a [LogRecord] as a shorthand
  /// for manually handling a log record.
  ///
  /// This is equivalent to calling the [handle] method.
  void call(LogRecord record) => handle(record);

  /// Cancels all active subscriptions to loggers and clears the subscription list.
  /// This is used internally by the [detachFromLoggers] and [dispose] methods to clean up resources.
  Future<void> _cancelSubscriptions() async {
    final futures = _subscriptions.map((sub) => sub.cancel()).toList(growable: false);
    _subscriptions.clear();
    await Future.wait<dynamic>(futures);
  }

  /// Cleans up the log appender by canceling all active subscriptions.
  /// This method must be called when the log appender is no longer needed to free up resources.
  ///
  /// Subclasses that override this method must call `super.dispose()` to ensure
  /// proper cleanup.
  @mustCallSuper
  Future<void> dispose() => _cancelSubscriptions();
}
