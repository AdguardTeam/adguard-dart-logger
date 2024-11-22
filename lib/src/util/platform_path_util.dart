import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class PlatformPathUtil {
  static String get platformSeparator => kIsWeb ? '/' : Platform.pathSeparator;
}
