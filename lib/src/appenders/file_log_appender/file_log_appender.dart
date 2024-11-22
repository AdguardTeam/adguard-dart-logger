import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/appenders/base_log_appender.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/controllers/meta_data_controller.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/controllers/rotation_file_controller.dart';
import 'package:adguard_logger/src/appenders/file_log_appender/storages/log_storage.dart';
import 'package:adguard_logger/src/util/archive_util.dart';
import 'package:adguard_logger/src/util/platform_path_util.dart';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

/// A [FileLogAppender] that handles logging messages to a file, with support for
/// file rotation based on size and date, as well as the ability to archive logs.
///
/// This class extends [BaseLogAppender] to provide file-based logging capabilities
/// with mechanisms for rotating log files when they reach specified size limits or
/// age thresholds.
class FileLogAppender extends BaseLogAppender {
  MetaDataController? _metaDataController;

  /// The policy for managing log file rotation.
  late final RotationFileController _rotationFileController;

  final StreamController<LogRecord> _flushController = StreamController.broadcast();

  StreamSubscription<List<LogRecord>>? _flushSub;

  StreamSubscription<List<LogMetaData>>? _metadataSub;

  final AsyncCache<void> _initializationCache = AsyncCache.ephemeral();

  final Duration _flushDuration;

  final LogStorage _logStorage;

  /// The file path where logs will be written.
  String filePath;

  /// Creates a [FileLogAppender] with the specified parameters.
  /// - [filePath] is the path of the log file without extension
  /// - [formatter] specifies how to format log messages to write
  /// - [rotationFileController] (optional) is used for managing file rotation.
  FileLogAppender({
    required this.filePath,
    required LogStorage logStorage,
    Duration flushDuration = const Duration(seconds: 2),
    RotationFileController? rotationFileController,
    MetaDataController? metaDataController,
  })  : _flushDuration = flushDuration,
        _rotationFileController = rotationFileController ?? RotationFileController(),
        _logStorage = logStorage,
        _metaDataController = metaDataController;

  /// Handles incoming log records.
  ///
  /// This method formats the log record, checks if the log file needs to be rotated,
  /// and writes the log message to the file. It also updates the current capacity of the
  /// log file and resets the debounce timer.
  @override
  FutureOr<void> handle(LogRecord record) async {
    if (_flushSub == null) {
      await _initializationCache.fetch(_init);
    }

    final rawData = utf8.encode(record.asMap.toString());

    final metadata = _metaDataController!.fetchMetadata();

    // Check if the log file needs to be rotated based on current conditions.
    if (_rotationFileController.shouldRotate(filePath, metadata, incomingData: rawData)) {
      filePath = _rotateFile(filePath);
    }

    _updateMetaData(filePath, rawData.length);

    // Write the formatted log data to the file.
    _flushController.add(record);

    // Update the current capacity of the log files.
    _rotationFileController.updateCapacity(rawData.length);

    await _performCapacityStatusCheck(filePath);
  }

  Future<void> _init() async {
    _metaDataController ??= await _initializeMetaDataManager();

    _flushSub = _flushController.stream.bufferTime(_flushDuration).listen((value) {
      if (value.isNotEmpty) {
        _writeData(value);
      }
    });

    _metadataSub = _metaDataController!.listen(_onMetadataUpdated);

    // Initialize the file and its rotation policies if the sink is not open.
    final initialFile = _rotationFileController.initializeFile(
      filePath,
      _metaDataController!.fetchMetadata(),
    );

    if (initialFile != null) {
      filePath = initialFile;
      await _performContainmentStatusCheck(filePath);
      await _performCapacityStatusCheck(filePath);
    }
  }

  Future<MetaDataController> _initializeMetaDataManager() async {
    final splitPath = filePath.split(PlatformPathUtil.platformSeparator);
    splitPath[splitPath.length - 1] = '.metadata';
    final metadataPath = splitPath.join(PlatformPathUtil.platformSeparator);
    List<LogMetaData> metaData = await _logStorage.readMetaData(metadataPath) ?? [];
    final path = splitPath.join(PlatformPathUtil.platformSeparator);
    
    if (metaData.isNotEmpty) {
      final directory = path.replaceAll('.metadata', '');
      final existingFiles = (await _logStorage.readFileNames(directory)).map((e) => basename(e)).toSet();
      metaData = metaData.where((e) => existingFiles.contains(e.id)).toList();
    }

    return MetaDataController(
      path,
      initialData: metaData,
    );
  }

  Future<void> _performContainmentStatusCheck(String filePath) async {
    List<String> filesToDelete;
    do {
      final metaData = _metaDataController!.fetchMetadata();
      filesToDelete = _rotationFileController.checkoutContainmentStatus(filePath, metaData) ?? [];
      await Future.wait(
        [
          for (final path in filesToDelete)
            Future.wait(
              [
                Future.sync(() {
                  final metadataId = basename(path);
                  _rotationFileController
                      .updateCapacity(-metaData.firstWhere((element) => element.id == metadataId).lengthInBytes);
                  _metaDataController!.deleteMetadata(metadataId);
                }),
                _logStorage.deleteData(path),
              ],
            )
        ],
      );
    } while (filesToDelete.isNotEmpty);
  }

  Future<void> _performCapacityStatusCheck(String filePath) async {
    List<String> filesToDelete;
    do {
      final metaData = _metaDataController!.fetchMetadata();
      filesToDelete = _rotationFileController.checkoutCapacityStatus(filePath, metaData) ?? [];
      await Future.wait(
        [
          for (final path in filesToDelete)
            Future.wait(
              [
                Future.sync(() {
                  final metadataId = basename(path);
                  _rotationFileController
                      .updateCapacity(-metaData.firstWhere((element) => element.id == metadataId).lengthInBytes);
                  _metaDataController!.deleteMetadata(metadataId);
                }),
                _logStorage.deleteData(path),
              ],
            )
        ],
      );
    } while (filesToDelete.isNotEmpty);
  }

  void _updateMetaData(String filePath, int updatedSize) {
    final metaData = _metaDataController!.fetchMetadata();
    final actualId = basename(filePath);
    final existingMetaData = metaData.firstWhereOrNull((element) => element.id == actualId);
    _metaDataController!.insertMetadata(
      LogMetaData(
          id: actualId,
          creationDate: existingMetaData?.creationDate ?? DateTime.now(),
          lengthInBytes: (existingMetaData?.lengthInBytes ?? 0) + updatedSize),
    );
  }

  /// Archives the current log data to a specified archive path.
  ///
  /// This method allows for optional password protection during archiving.
  Future<Uint8List> archiveData({
    Duration? lastModifiedDuration,
    Map<String, Uint8List> additionalFiles = const {},
  }) async {
    final paths = _rotationFileController.getRotatedPaths(
      filePath,
      _metaDataController!.fetchMetadata().map((el) => el.id).toList(),
    );
    final Map<String, Uint8List> files = {};
    await Future.wait([
      for (final path in paths)
        _logStorage.readLogData(path, modifiedDuration: lastModifiedDuration).then(
          (value) {
            if (value == null) return null;
            return files[basename(path)] = utf8.encode(value);
          },
        ),
    ]);

    final archivedData = await ArchiveUtil.archive(
      {
        ...additionalFiles,
        ...files,
      },
    );

    return archivedData;
  }

  /// Writes data to the log file using the current write sink.
  Future<void> _writeData(List<LogRecord> data) => _logStorage.writeLogData(
        filePath,
        data,
      );

  Future<void> _onMetadataUpdated(List<LogMetaData> metadata) =>
      _logStorage.writeMetaData(_metaDataController!.path, metadata);

  /// Rotates the current log file according to the rotation policy.
  ///
  /// This method closes the current write sink, creates a new log file, and returns
  /// the newly created file.
  String _rotateFile(String path) {
    _flushSub?.pause();

    final paths = _rotationFileController.getRotatedPaths(
        filePath, _metaDataController!.fetchMetadata().map((el) => el.id).toList());

    final rotatedFile = _rotationFileController.rotateFile(path, paths);

    _flushSub?.resume();
    return rotatedFile;
  }

  /// Closes the current write sink and cancels the debounce timer.
  @override
  Future<void> dispose() async {
    super.dispose();
    _flushSub?.cancel();
    _metadataSub?.cancel();
  }
}
