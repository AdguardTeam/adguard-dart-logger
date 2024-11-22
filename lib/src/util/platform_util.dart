abstract class PlatformUtil {
  static bool get kIsWeb => const bool.fromEnvironment('dart.library.js_util');
}
