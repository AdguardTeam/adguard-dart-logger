import 'dart:io';

abstract class PlatformPathUtil {
  static bool get _kIsWeb => const bool.fromEnvironment('dart.library.js_util');

  static String get platformSeparator => _kIsWeb ? '/' : Platform.pathSeparator;
}
