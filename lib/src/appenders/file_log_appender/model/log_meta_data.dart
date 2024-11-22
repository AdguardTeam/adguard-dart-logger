/// A data class that represents the creation information of a file.
///
/// The [LogMetaData] class contains the file's unique identifier and
/// its creation date. This class provides methods to convert the file data
/// between `Map<String, dynamic>` and object form, enabling easy storage
/// and retrieval of metadata.
class LogMetaData {
  /// The key used to identify the file's ID in a map.
  static const _idKey = 'id';

  /// The key used to identify the file's creation date in a map.
  static const _creationDateKey = 'creationDate';

  static const _lengthInBytesKey = 'lengthInBytes';

  /// The creation date of the file.
  final DateTime creationDate;

  /// The unique identifier of the file.
  final String id;

  final int lengthInBytes;

  /// Constructs a [LogMetaData] instance with the given [id] and [creationDate].
  ///
  /// - [id]: The unique identifier for the file.
  /// - [creationDate]: The date and time when the file was created.
  LogMetaData({
    required this.id,
    required this.creationDate,
    required this.lengthInBytes,
  });

  /// Creates an instance of [LogMetaData] from a map.
  ///
  /// This factory constructor extracts the file's [id] and [creationDate] from the map.
  /// The [creationDate] is expected to be in milliseconds since epoch.
  ///
  /// - [map]: A map containing the file metadata with keys [_idKey] and [_creationDateKey].
  factory LogMetaData.fromMap(Map<String, dynamic> map) {
    return LogMetaData(
      id: map[_idKey],
      creationDate: DateTime.fromMillisecondsSinceEpoch(map[_creationDateKey]),
      lengthInBytes: map[_lengthInBytesKey],
    );
  }

  /// Converts this instance of [LogMetaData] into a map.
  ///
  /// The map contains the [id] and the [creationDate] in milliseconds since epoch.
  /// This method is useful for persisting the metadata in storage.
  ///
  /// Returns a map with keys 'id' and 'creationDate' representing the file data.
  Map<String, Object> toMap() => {
        _idKey: id,
        _creationDateKey: creationDate.millisecondsSinceEpoch,
        _lengthInBytesKey: lengthInBytes,
      };
}
