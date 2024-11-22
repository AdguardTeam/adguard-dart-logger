import 'dart:async';

import 'package:adguard_logger/adguard_logger.dart';

@pragma('vm:entry-point')
void main([List<String>? args]) {
  runZonedGuarded<Future<void>>(() async {
    final consoleAppender = ConsoleLogAppender();
    consoleAppender.attachToLogger(logger);
    logger.logInfo('Info message');
    logger.listenableLevel = LogLevel.debug;
    logger.logDebug('Debug message');

    throw Exception('Test error message');
  }, (error, stackTrace) {
    logger.logError(
      'Error captured in the main zone!',
      error: error,
      stackTrace: stackTrace,
    );
  }, zoneValues: {
    Logger.loggerKey: logger,
  });
}
