import 'package:adguard_logger/src/model/log_data.dart';
import 'package:adguard_logger/src/model/log_record.dart';
import 'package:adguard_logger/src/formatters/logger_base_formatter.dart';

/// A formatter for logging data records in a structured format.
class DataLoggerFormatter extends LoggerBaseFormatter {
  /// The list of logging data types to include in the formatted output.
  final List<LoggingData> _loggingData;

  /// Creates an instance of [DataLoggerFormatter].
  ///
  /// [loggingData] - An optional list of [LoggingData] types to be included in the output.
  /// If not provided, defaults to a predefined set of logging data types.
  const DataLoggerFormatter({
    List<LoggingData> loggingData = const [
      LoggingData.time(),
      LoggingData.level(),
      LoggingData.trace(),
      LoggingData.separator('\n'),
      LoggingData.message(),
      LoggingData.separator('\n'),
      LoggingData.error(),
      LoggingData.separator('\n'),
      LoggingData.stackTrace(),
    ],
  }) : _loggingData = loggingData;

  /// The separator to use between logged data items if no separator provided.
  String get separator => ' ';

  /// Wraps the given [text] with specified enclosing characters.
  ///
  /// [text] - The text to wrap.
  /// [startCharacter] - The character to use at the start (default is '[').
  /// [endCharacter] - The character to use at the end (default is ']').
  String wrapWithEnclosingCharacters(
    String text, {
    String startCharacter = '[',
    String endCharacter = ']',
  }) =>
      '$startCharacter$text$endCharacter';

  /// Formats the given [LogRecord] into a string representation.
  ///
  /// [rec] - The log record to format.
  /// Returns the formatted string.
  @override
  String format(LogRecord rec) => formatToStringBuffer(rec, StringBuffer()).toString().trim();

  /// Formats the given [LogRecord] into a [StringBuffer].
  ///
  /// [rec] - The log record to format.
  /// [sb] - The string buffer to append the formatted output.
  /// Returns the modified [StringBuffer].
  @override
  StringBuffer formatToStringBuffer(LogRecord rec, StringBuffer sb) {
    final mappedRecord = rec.asMap; // Maps the log record to its data types
    bool isHeaderClosed = false;
    bool isAdditionalTagsInserted = false;

    for (int i = 0; i < _loggingData.length; i++) {
      final dataType = _loggingData[i]; // Get the current logging data type
      final isRecordHasAdditionalTags = rec.additionalTags?.isNotEmpty ?? false;
      final isRecordHasMessageType = dataType == const LoggingData.message();

      // If the dataType contains data but is not present in the mapped record
      if (dataType.containsData && !mappedRecord.containsKey(dataType)) {
        // Skip only the missing data item, but DO NOT skip separators.
        // This ensures that header separators like '\n' are still emitted,
        // so the message moves to a new line even if some header fields are absent.
        continue;
      }

      // If the current data type does not contain data, write its separator
      if (!dataType.containsData) {
        // Insert additional tags right before the first newline separator (end of header)
        if (!isAdditionalTagsInserted && !isHeaderClosed && dataType.separator == '\n' && isRecordHasAdditionalTags) {
          final tags = rec.additionalTags!;
          for (int t = 0; t < tags.length; t++) {
            sb.write(wrapWithEnclosingCharacters(tags[t]));
            if (t != tags.length - 1) sb.write(separator);
          }
          isAdditionalTagsInserted = true;
        }
        if (dataType.separator == '\n') {
          isHeaderClosed = true;
        }

        sb.write(dataType.separator);
        continue;
      }
      // Get the value to write from the mapped record
      var valueToWrite = mappedRecord[dataType]!;

      // Fallback: if there was no newline separator before message,
      // ensure additional tags are printed immediately before the message.
      if (!isAdditionalTagsInserted && !isHeaderClosed && isRecordHasMessageType && isRecordHasAdditionalTags) {
        final tags = rec.additionalTags!;
        for (int t = 0; t < tags.length; t++) {
          sb.write(wrapWithEnclosingCharacters(tags[t]));
          if (t != tags.length - 1) sb.write(separator);
        }

        sb.write(separator);
        isAdditionalTagsInserted = true;
      }

      // Wrap the value if necessary based on the data type
      if (dataType.shouldWrap) {
        valueToWrite = wrapWithEnclosingCharacters(valueToWrite);
      }

      sb.write(valueToWrite); // Write the value to the StringBuffer
      // Write the separator if not the last item
      if (_loggingData.length - 1 != i) {
        sb.write(dataType.separator ?? separator);
      }
    }

    return sb; // Return the modified StringBuffer
  }
}
