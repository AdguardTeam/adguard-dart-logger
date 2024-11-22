import 'dart:io';

import 'package:adguard_logger/src/util/platform_util.dart';


abstract class PlatformPathUtil {
  static String get platformSeparator => PlatformUtil.kIsWeb ? '/' : Platform.pathSeparator;
}
