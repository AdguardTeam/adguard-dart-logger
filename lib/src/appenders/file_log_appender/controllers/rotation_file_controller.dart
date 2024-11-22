import 'package:adguard_logger/src/appenders/file_log_appender/model/log_meta_data.dart';
import 'package:adguard_logger/src/util/platform_path_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

const _kDefaultFileCapacity = 1024 * 1024;

/// A policy class that manages file rotation based on size, time, and file limits.
/// This class handles the creation, deletion, and maintenance of rotated log files.
class RotationFileController {
  /// The limit on the total size of all rotated files before older files are deleted.
  final int rotationSizeLimit;

  /// The size limit for a single file before it needs to be rotated.
  final int rotationFileLimit;

  /// The duration to keep rotated files before they are deleted.
  final int? containmentDaysDuration;

  /// The file suffix for rotated files (e.g., `.log`).
  final String rotationFileSuffix;

  /// The date format to use in rotated file names.
  final String rotationPrefixDateFormat;

  /// The predicate used to separate parts of the file name (e.g., date, index).
  final String rotationPredicate;

  /// Creates a new instance of [RotationFileController].
  ///
  /// - [rotationSizeLimit]: The limit on the total size of rotated files.
  /// - [rotationFileLimit]: The maximum size for a single log file before rotation.
  /// - [containmentDaysDuration]: The number of days to keep log files before deleting.
  /// - [rotationFileSuffix]: The suffix to append to rotated files (e.g., `.log`).
  /// - [rotationPrefixDateFormat]: The date format for naming rotated files.
  /// - [rotationPredicate]: The delimiter used in the file name for separating date and id.
  RotationFileController({
    this.rotationSizeLimit = _kDefaultFileCapacity * 10,
    this.rotationFileLimit = _kDefaultFileCapacity,
    this.containmentDaysDuration = 1,
    this.rotationFileSuffix = '.log',
    this.rotationPrefixDateFormat = 'yyyy-MM-dd',
    this.rotationPredicate = '_',
  }) : assert(
          rotationFileLimit <= rotationSizeLimit,
          'Rotation limit of single file must be not greater than the size limit of all log files.',
        );

  /// Current capacity of files being tracked for rotation.
  int _actualCapacity = 0;

  /// Initializes the rotation policies by performing size and time-based rotation checks.
  /// Returns the most recent rotated file, if available.
  String? initializeFile(String path, List<LogMetaData> metaData) {
    final paths = _getRotatedFiles(path, metaData.map((el) => el.id).toList());
    final lastFile = paths.firstWhereOrNull((element) => element.endsWith(metaData.last.id));
    final result = lastFile ?? paths.lastOrNull;
    return result == null ? null : _replacePathChild(path, result);
  }

  /// Checks whether the log files need to be rotated based on time (containment) conditions.
  List<String>? checkoutContainmentStatus(String path, List<LogMetaData> metaData) {
    if (containmentDaysDuration == null) return null;

    final filesToDelete = metaData
        .where((element) => _checkContainmentCondition(element.creationDate))
        .map((e) => _replacePathChild(path, e.id))
        .toList();

    return filesToDelete.isEmpty ? null : filesToDelete;
  }

  /// Checks whether the file size exceeds the rotation limit and rotates if necessary.
  List<String>? checkoutCapacityStatus(String path, List<LogMetaData> metaData) {
    if (_actualCapacity < rotationSizeLimit) return null;
    int capacityToReduce = 0;
    final filesToRemove = metaData.takeWhile((element) {
      final condition = capacityToReduce < (_actualCapacity - rotationSizeLimit);
      capacityToReduce += element.lengthInBytes;
      return condition;
    }).toList();
    final result = filesToRemove.map((e) => _replacePathChild(path, e.id)).toList();
    return result.isEmpty ? null : result;
  }

  /// Updates the current capacity by the given file size.
  void updateCapacity(int size) => _actualCapacity += size;

  /// Determines whether a file should be rotated based on its size or age.
  bool shouldRotate(String path, List<LogMetaData> metadata, {Uint8List? incomingData}) {
    final rotationFile = metadata.firstWhereOrNull((element) => element.id == basename(path));
    if (rotationFile == null) {
      return true;
    }
    final fileSizeExceedsLimit = rotationFile.lengthInBytes + (incomingData?.length ?? 0) >= rotationFileLimit;

    if (fileSizeExceedsLimit) {
      return true;
    }

    return _checkContainmentCondition(rotationFile.creationDate);
  }

  /// Creates a new rotated file with an updated name based on the current date and index.
  String rotateFile(String path, List<String> availablePaths) {
    final metaInfo = _getFileMetaInfo(path);
    final actualDate = DateFormat(rotationPrefixDateFormat).format(DateTime.now());
    final rotatedFiles = _getRotatedFiles(path, availablePaths, baseDate: actualDate);
    int? newId;

    if (rotatedFiles.isNotEmpty) {
      final lastFileId = _getFileMetaInfo(rotatedFiles.last).id;
      newId = _getNextFileId(lastFileId);
    }

    final newPath = _replacePathChild(path, _buildFileName(metaInfo.baseName, newId));

    return newPath;
  }

  /// Checks whether the file's age exceeds the allowed containment duration.
  bool _checkContainmentCondition(DateTime fileDate) {
    final currentDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final compareData = fileDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final differentInDays = currentDate.difference(compareData).inDays;

    return containmentDaysDuration != null && differentInDays > (containmentDaysDuration! - 1);
  }

  /// Retrieves all rotated files from the directory matching the base file name and optional date.
  List<String> getRotatedPaths(String filePath, List<String> availableIds) {
    final fileInfo = _getFileMetaInfo(filePath);
    final rotatedFiles = _getRotatedFiles(filePath, availableIds, baseDate: fileInfo.date);
    return rotatedFiles.map((e) => _replacePathChild(filePath, e)).toList();
  }

  /// Retrieves a list of rotated files matching the base name and optional date.
  List<String> _getRotatedFiles(String path, List<String> availableFiles, {String? baseDate}) {
    final fileMetaInfo = _getFileMetaInfo(path);

    return availableFiles.where((file) {
      final metaInfo = _getFileMetaInfo(file);
      var condition = metaInfo.baseName == fileMetaInfo.baseName && file.endsWith(rotationFileSuffix);
      if (baseDate != null) {
        condition = condition && metaInfo.date == baseDate;
      }
      return condition;
    }).toList();
  }

  /// Extracts the meta information (base name, date, and index) from the file name.
  ({String baseName, String? date, int? id}) _getFileMetaInfo(String name) {
    final separator = PlatformPathUtil.platformSeparator;

    final parts = name.split(separator).last.split(rotationPredicate);
    var baseName = parts.first;
    final trailing = parts.last.replaceAll(rotationFileSuffix, '');

    return (
      baseName: baseName,
      date: parts.elementAtOrNull(1)?.replaceAll(rotationFileSuffix, ''),
      id: int.tryParse(trailing)
    );
  }

  /// Calculates the next available file ID for rotation.
  int? _getNextFileId(int? lastFileId) => ((lastFileId ?? 0) + 1);

  /// Builds the file name for a rotated file using the base name, date, and ID.
  String _buildFileName(String baseName, int? id) {
    final date = DateFormat(rotationPrefixDateFormat).format(
      DateTime.now(),
    );
    final idPart = id != null ? '$rotationPredicate$id' : '';
    return '$baseName$rotationPredicate$date$idPart$rotationFileSuffix';
  }

  String _replacePathChild(String path, String child) {
    final separator = PlatformPathUtil.platformSeparator;
    final splitPath = path.split(separator);

    splitPath[splitPath.length - 1] = child;

    return splitPath.join(separator);
  }
}
