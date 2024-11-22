import 'package:adguard_logger/src/util/platform_path_util.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class to manage file containment paths across different platforms.
/// Provides a method to get the appropriate platform-specific directory for storing files.
///
/// This class supports mobile and desktop platforms, and raises an error if accessed from the web.
///
/// **Usage:**
///
/// ```dart
/// String path = await ContainmentFileUtil.getPlatformContainmentDirectoryPath('example.txt');
/// print(path); // Outputs the platform-specific path to 'example.txt'
/// ```
///
/// Throws [UnimplementedError] if called on the web.
abstract class ContainmentFileUtil {
  /// Retrieves the platform-specific directory path for storing a file, and appends the given [fileName].
  ///
  /// For mobile and desktop platforms, this method uses `getApplicationSupportDirectory`
  /// from the `path_provider` package to obtain the path where application support files can be stored.
  ///
  /// If called from a web platform (`kIsWeb` is true), it throws an [UnimplementedError],
  /// as the web does not provide direct access to the file system.
  ///
  /// This method can also throw an [Exception] if there is an error retrieving the directory path.
  ///
  /// ### Returns:
  /// A `Future<String>` that resolves to the full platform-specific file path, where the file
  /// can be stored.
  ///
  /// ### Throws:
  /// - [UnimplementedError]: If the method is called on the web platform.
  /// - [Exception]: If there is a failure while trying to retrieve the directory path on non-web platforms.
  static Future<String> getPlatformContainmentDirectoryPath(String fileName) async {
    if (kIsWeb) {
      // Web platform does not support direct file system access.
      throw UnimplementedError('File containment directory is not supported on the web.');
    }

    try {
      // Get the application support directory on non-web platforms.
      final directory = await getApplicationSupportDirectory();

      // Return the full path by appending the provided fileName.
      return '${directory.path}${PlatformPathUtil.platformSeparator}$fileName';
    } catch (e) {
      // If an error occurs, throw an exception with a detailed message.
      throw Exception('Failed to retrieve containment directory path: $e');
    }
  }
}
