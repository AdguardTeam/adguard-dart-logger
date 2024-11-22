import 'dart:async';

import 'package:adguard_logger/src/formatters/logger_base_formatter.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';

/// Abstract class that defines the interface for log storage.
/// This includes methods for writing, reading, and deleting log data and metadata.
abstract class LogStorage {
  /// The log formatter used to format logs before storing them.
  final LoggerBaseFormatter formatter;

  const LogStorage({
    required this.formatter,
  });

  /// Writes metadata to the storage at the given [path].
  Future<void> writeMetaData(String path, List<LogMetaData> data);

  /// Writes log records to the storage at the given [path].
  Future<void> writeLogData(
    String path,
    List<LogRecord> data,
  );

  /// Deletes data at the specified [path].
  Future<void> deleteData(String path);

  /// Reads log data from the storage at the specified [path].
  /// Returns a [String] containing the log data or `null` if no data is found.
  /// Optionally filters logs by [modifiedDuration], which filters logs based on last modification time.
  Future<String?> readLogData(String path, {Duration? modifiedDuration});

  /// Reads metadata from the storage at the specified [path].
  /// Returns a list of [LogMetaData] or `null` if no metadata is found.
  Future<List<LogMetaData>?> readMetaData(String path);

  Future<List<String>> readFileNames(String directory);
}
