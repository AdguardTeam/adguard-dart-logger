import 'dart:convert';
import 'dart:io';

import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';
import 'package:adguard_logger/src/formatters/data_logger_formatter.dart';
import 'package:adguard_logger/src/formatters/logger_base_formatter.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/storages/log_storage.dart';

/// An implementation of [LogStorage] that uses the file system to store logs.
/// Log files and metadata are stored as plain text files.
/// Should be used only on IO platforms.
class FileLogStorage implements LogStorage {
  @override
  final LoggerBaseFormatter formatter;

  FileLogStorage({
    this.formatter = const DataLoggerFormatter(),
  });

  /// Deletes the file at the given [path] if it exists.
  @override
  Future<void> deleteData(String path) async {
    if (await File(path).exists()) {
      await File(path).delete();
    }
  }

  /// Reads log data from the file at the given [path].
  /// Optionally, filters logs by [modifiedDuration], which ensures that only logs modified
  /// within the specified duration are returned.
  @override
  Future<String?> readLogData(String path, {Duration? modifiedDuration}) async {
    if (!(await File(path).exists())) {
      return null;
    }

    // Check if the file was modified within the specified duration
    if (modifiedDuration != null) {
      final lastModificationData = await File(path).lastModified();
      if (DateTime.now().difference(lastModificationData) > modifiedDuration) {
        return null;
      }
    }

    return await File(path).readAsString();
  }

  /// Reads metadata from the file at the specified [path].
  /// The metadata is expected to be a JSON-encoded list of [LogMetaData].
  @override
  Future<List<LogMetaData>?> readMetaData(String path, {bool decode = true}) async {
    if (!(await File(path).exists())) {
      return null;
    }
    try {
      final metaData = await File(path).readAsString();
      final metaDataList = jsonDecode(metaData) as List;
      return metaDataList.map((e) => LogMetaData.fromMap(e)).toList();
    } catch (e) {
      //* In migration purposes
      await deleteData(path);
      return null;
    }
  }

  /// Writes a list of [LogMetaData] to the file at the specified [path].
  @override
  Future<void> writeMetaData(String path, List<LogMetaData> data) async {
    final mappedMetaData = data.map((e) => e.toMap()).toList();
    await File(path).writeAsString(jsonEncode(mappedMetaData));
  }

  /// Writes a list of [LogRecord] to the file at the specified [path].
  /// Log records are serialized using the formatter and written to the file as strings.
  @override
  Future<void> writeLogData(String path, List<LogRecord> data) async {
    final mappedData = data.map((e) => formatter.format(e)).join(Platform.lineTerminator);
    await File(path).writeAsString(
      mappedData,
      mode: FileMode.writeOnlyAppend,
    );
  }

  @override
  Future<List<String>> readFileNames(String directory) => Directory(directory)
      .list()
      .where(
        (event) => event is File,
      )
      .map((e) => e.path)
      .toList();
}
