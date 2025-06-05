import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Utility class for archiving files into a ZIP archive.
/// This class provides methods for creating ZIP files from in-memory file data,
/// allowing easy and efficient compression of multiple files into a single archive.
///
/// It supports compressing files with the highest level of compression and returns
/// the resulting ZIP file data as a [Uint8List], which can then be saved or used as needed.
abstract class ArchiveUtil {
  /// Archives the provided list of [archiveFiles] into a ZIP file.
  ///
  /// The input is a map of file names (as keys) and their corresponding content in [Uint8List] format (as values).
  /// This method does not write the ZIP file to the disk, but instead returns the ZIP archive's content
  /// as a [Uint8List], which can be used to save the ZIP to a file or transfer it over the network.
  ///
  ///
  /// ### Returns:
  /// A `Future<Uint8List>` that completes with the bytes of the created ZIP archive.
  ///
  /// ### Example usage:
  /// ```dart
  /// Map<String, Uint8List> filesToArchive = {
  ///   'file1.txt': await File('file1.txt').readAsBytes(),
  ///   'image.png': await File('image.png').readAsBytes(),
  /// };
  ///
  /// Uint8List zipData = await ArchiveUtil.archive(filesToArchive);
  ///
  /// // Now zipData can be written to a file or sent over the network
  /// await File('output.zip').writeAsBytes(zipData);
  /// ```
  ///
  /// ### Details:
  /// - This method uses the [ZipEncoder] from the `archive` package to compress the files.
  /// - It adds each file's data to the archive using [ArchiveFile.stream], which efficiently handles the file's byte stream.
  /// - The archive is compressed using the best available compression level (`Deflate.BEST_COMPRESSION`).
  ///
  /// ### Throws:
  /// - This method may throw an [Exception] if any of the provided file data is invalid or the compression process fails.
  static Future<Uint8List> archive(Map<String, Uint8List> archiveFiles) async {
    // Initializes the ZIP encoder and creates an empty archive.
    final encoder = ZipEncoder();
    final archive = Archive();

    // Iterates over the provided files and adds each one to the archive.
    for (final file in archiveFiles.entries) {
      final stream = InputMemoryStream(
        file.value,
        length: file.value.length,
      );
      archive.addFile(ArchiveFile.stream(
        file.key, // The file name
        stream, // The file data stream
      ));
    }

    // Initializes an output stream with little-endian byte order (platform-independent).
    final outputStream = OutputMemoryStream(
      byteOrder: ByteOrder.littleEndian,
    );

    // Compresses the archive with the highest compression level and returns the result as a byte list.
    final bytes = encoder.encode(
      archive,
      level: DeflateLevel.bestCompression,
      output: outputStream,
    );

    // Returns the generated ZIP file as a Uint8List.
    return Uint8List.fromList(bytes);
  }
}
