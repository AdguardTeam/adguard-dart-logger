import 'dart:developer';

import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/formatters/data_logger_formatter.dart';
import 'package:adguard_logger/src/formatters/logger_base_formatter.dart';
import 'package:adguard_logger/src/appenders/base_log_appender.dart';

/// A log appender that outputs log records to the console.
///
/// This class extends [BaseLogAppender] and is used to handle log records
/// by formatting them and sending the output to the console using `debugPrint`.
class ConsoleLogAppender extends BaseLogAppender {
  /// The formatter used to format log records before outputting them to the console.
  /// Defaults to [DataLoggerFormatter], but can be customized via the constructor.
  final LoggerBaseFormatter formatter;

  /// Creates a new instance of [ConsoleLogAppender] with an optional custom [formatter].
  ///
  /// - [formatter]: The formatter used to format the log records. If not provided,
  ///   it defaults to [DataLoggerFormatter].
  ConsoleLogAppender({
    this.formatter = const DataLoggerFormatter(),
  });

  /// Handles a [LogRecord] by formatting it and printing the output to the console.
  /// This method overrides [BaseLogAppender.handle].
  ///
  /// - [record]: The log record to be handled and printed.
  @override
  void handle(LogRecord record) => log(formatter.format(record), name: 'AdGuard Log');
}
