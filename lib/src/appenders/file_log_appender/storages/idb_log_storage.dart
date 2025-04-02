import 'dart:async';
import 'dart:convert';

import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/storages/log_storage.dart';
import 'package:adguard_logger/src/formatters/data_logger_formatter.dart';
import 'package:adguard_logger/src/formatters/no_sql_logger_formatter.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:idb_shim/idb_browser.dart';

/// An implementation of [LogStorage] that uses IndexedDB to store logs.
/// Logs and metadata are stored as objects in an IndexedDB database.
class IDbLogStorage implements LogStorage {
  static const _logObjectNameStore = 'logs'; // Store name for log data
  static const _pathIndex = 'file_name'; // Index to track logs by file name
  static const _dataKey = 'data'; // Key used to store log data

  static const _defaultDatabaseVersion = 1; // Default database version

  final String dataBaseName; // Name of the IndexedDB database
  final int databaseVersion; // Version of the IndexedDB schema
  late final Database _database; // The database instance

  @override
  NoSqlLoggerFormatter get formatter => const NoSqlLoggerFormatter(); // Formatter used for log serialization

  /// Constructor for creating an [IDbLogStorage] instance.
  /// Requires the [dataBaseName] and [databaseVersion] for IndexedDB.
  IDbLogStorage({
    required this.dataBaseName,
    this.databaseVersion = _defaultDatabaseVersion,
  });

  /// Initializes the IndexedDB database and ensures that the necessary object store is created.
  Future<void> init() async => _database = await getIdbFactory()!.open(
        dataBaseName,
        version: databaseVersion,
        onUpgradeNeeded: (event) {
          final db = event.database;
          if (!db.objectStoreNames.contains(_logObjectNameStore)) {
            final objectStore = db.createObjectStore(_logObjectNameStore, autoIncrement: true);
            objectStore.createIndex(_pathIndex, _pathIndex, unique: false, multiEntry: false);
          }
        },
      );

  /// Returns the object store for log data transactions.
  Future<ObjectStore?> _tryGetObjectStore() async {
    try {
      return _objectStore;
    } catch (err) {
      // If the database is not initialized or closed, reinitialize it
      try {
        await init();
        return _objectStore;
      } catch (e) {
        return null;
      }
    }
  }

  ObjectStore get _objectStore =>
      _database.transaction(_logObjectNameStore, idbModeReadWrite).objectStore(_logObjectNameStore);

  /// Writes metadata to the IndexedDB object store at the specified [path].
  /// If metadata for the given path already exists, it is updated.
  @override
  Future<void> writeMetaData(String path, List<LogMetaData> data) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return;

    final decodedData = data.map((e) => e.toMap()).toList();
    bool found = false;

    final cursorListener = currentStore.index(_pathIndex).openCursor(key: path).listen((cursor) async {
      await cursor.update({_pathIndex: path, _dataKey: decodedData});
      found = true;
    });
    await cursorListener.asFuture();
    await cursorListener.cancel();
    if (found) {
      return;
    }

    await currentStore.put({_pathIndex: path, _dataKey: decodedData});
  }

  /// Writes log records to the IndexedDB object store at the specified [path].
  /// Log records are formatted using the formatter and stored as JSON objects.
  @override
  Future<void> writeLogData(String path, List<LogRecord> data) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return;

    final mutableDataList = data.toList();

    await Future.wait([
      for (final decodedData in mutableDataList)
        currentStore.put({
          _pathIndex: path,
          _dataKey: jsonDecode(
            formatter.format(
              decodedData,
            ),
          ),
        })
    ]);
  }

  /// Reads log records from IndexedDB at the specified [path].
  /// Optionally filters records by [modifiedDuration], which filters based on log modification time.
  @override
  Future<String?> readLogData(String path, {Duration? modifiedDuration}) async {
    const outputFormatter = DataLoggerFormatter();
    var records = await _getRecordsFromDb(path);
    final resultBuffer = StringBuffer();

    if (modifiedDuration != null) {
      records =
          records.where((element) => DateTime.now().difference(element.timeLog.dateTime) <= modifiedDuration).toList();
    }

    if (records.isEmpty) {
      return null;
    }
    for (final record in records) {
      resultBuffer.writeln(outputFormatter.format(record));
    }

    return resultBuffer.toString();
  }

  /// Helper method to fetch all [LogRecord]s for the given [path] from the IndexedDB.
  Future<List<LogRecord>> _getRecordsFromDb(String path) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return [];

    final cursor = currentStore.index(_pathIndex).openCursor(
          key: path,
          autoAdvance: true,
        );
    List<LogRecord> records = [];
    await cursor.listen((cursor) {
      final value = (cursor.value as Map<String, dynamic>)[_dataKey] as Map<String, dynamic>;
      final record = formatter.decodeFromJson(value);
      records.add(record);
    }).asFuture();
    return records;
  }

  /// Deletes log data from IndexedDB at the specified [path].
  @override
  Future<void> deleteData(String path) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return;

    final cursor = currentStore.index(_pathIndex).openCursor(
          key: path,
          autoAdvance: true,
        );

    await cursor.listen((c) => c.delete()).asFuture();
  }

  /// Reads metadata from IndexedDB at the specified [path].
  /// Returns a list of [LogMetaData] or an empty list if no metadata is found.
  @override
  Future<List<LogMetaData>> readMetaData(String path) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return [];

    final metaData = await currentStore.index(_pathIndex).get(path) as Map?;
    if (metaData == null) {
      return [];
    }
    return (metaData[_dataKey] as List).cast<Map<String, dynamic>>().map((e) => LogMetaData.fromMap(e)).toList();
  }

  @override
  Future<List<String>> readFileNames(String path) async {
    final currentStore = await _tryGetObjectStore();
    if (currentStore == null) return [];

    final allValues = await currentStore.index(_pathIndex).getAll();
    final indexes = allValues.map((e) => (e as Map<String, dynamic>)[_pathIndex]).toSet();
    return indexes.cast<String>().toList();
  }
}
