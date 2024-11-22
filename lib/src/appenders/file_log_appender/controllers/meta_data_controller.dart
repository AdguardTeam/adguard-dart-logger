import 'dart:async';

import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';
import 'package:rxdart/rxdart.dart';

/// The `MetaDataManager` class manages the metadata associated with log files
/// by providing methods to fetch, insert, and delete metadata in a debounced
/// manner. The metadata is stored in a JSON-encoded file and is buffered in
/// memory to minimize the number of disk operations.
///
/// This class supports asynchronous initialization and controlled flushing
/// (writing) of metadata to disk after a configurable debounce period.

class MetaDataController {
  /// The default name of the metadata file used for storing metadata.
  static const String metadataDefaultName = '.metadata';

  /// A subscription to the stream that controls debounced flush operations.
  /// This ensures that metadata changes are written to disk only after a
  /// specified delay to avoid excessive disk writes.
  late StreamSubscription _flushSub;

  /// The debounce duration that defines the delay between metadata updates
  /// and the actual write operation. This helps in bundling multiple changes
  /// into a single disk write.
  final Duration _flushDebounceDuration;

  /// A stream controller that manages the stream of metadata changes and
  /// triggers write operations when the data is ready to be flushed to disk.
  final StreamController<List<LogMetaData>> _flushController = StreamController();

  /// The file path where the metadata is stored.
  late String path;

  /// An internal buffer that holds metadata in memory to reduce the frequency
  /// of disk read and write operations.
  late List<LogMetaData> _buffer;

  /// Creates a new instance of `MetaDataManager`.
  ///
  /// The [path] parameter specifies the location of the metadata file.
  /// The [flushDebounceDuration] parameter defines the delay between
  /// metadata changes and the actual write operation (defaults to 2 seconds).
  MetaDataController(
    this.path, {
    Duration flushDebounceDuration = const Duration(seconds: 2),
    List<LogMetaData> initialData = const [],
  })  : _flushDebounceDuration = flushDebounceDuration,
        _buffer = initialData.toList();

  /// Returns a copy of the metadata currently stored in memory.
  ///
  /// This method provides a snapshot of the current state of the metadata
  /// without reading from disk. It allows for quick access to the metadata.
  List<LogMetaData> fetchMetadata() => _buffer.toList();

  /// Inserts new metadata or updates existing metadata in memory.
  ///
  /// If metadata with the same [id] already exists, it is replaced with the
  /// new data. Otherwise, the new metadata is added. The metadata is then
  /// scheduled to be written to disk.
  ///
  /// - [data]: The new or updated metadata to be stored.
  void insertMetadata(LogMetaData data) {
    final metadata = fetchMetadata();
    final index = metadata.indexWhere((element) => element.id == data.id);
    if (index != -1) {
      metadata.removeAt(index);
    }
    metadata.add(data);
    _flush(metadata);
  }

  /// Deletes metadata by its [id] from memory and schedules a flush to update
  /// the stored metadata on disk.
  ///
  /// If the metadata with the specified [id] does not exist, no changes are made.
  ///
  /// - [id]: The unique identifier of the metadata to be removed.
  void deleteMetadata(String id) async {
    final metadata = fetchMetadata();
    final index = metadata.indexWhere((element) => element.id == id);
    if (index == -1) {
      return;
    } else {
      metadata.removeAt(index);
    }
    _flush(metadata);
  }

  /// Triggers a flush (write) operation by adding the updated metadata to the
  /// flush stream. The data will be written to disk after the debounce delay.
  ///
  /// - [data]: The updated metadata to be written to disk.
  void _flush(List<LogMetaData> data) {
    _buffer = data.toList();
    _flushController.add(_buffer);
  }

  StreamSubscription<List<LogMetaData>> listen(void Function(List<LogMetaData> data) onData) =>
      _flushController.stream.debounceTime(_flushDebounceDuration).listen(onData);

  /// Cleans up resources by canceling the flush subscription and writing any
  /// remaining buffered metadata to disk.
  ///
  /// This method should be called when the `MetaDataManager` is no longer needed
  /// to ensure that all pending writes are completed.
  Future<void> dispose() async {
    await _flushSub.cancel();
    await _flushController.close();
  }
}
