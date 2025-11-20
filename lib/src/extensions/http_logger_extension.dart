import 'package:adguard_logger/src/logger.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// A logger extension for logging HTTP requests and responses.
///
/// This extension is designed to log the details of HTTP requests and responses,
/// including the method, URL, status code, duration, and any errors that may occur.
class HttpLoggerExtension extends LoggerExtension<HttpLoggerExtension> {
  @protected
  final Map<String, DateTime> requestsSendTime = {};

  /// Logs a failed HTTP request.
  ///
  /// This method captures the request method, URL, request ID (if provided),
  /// and the duration it took to receive a response. It logs the error
  /// associated with the request.
  ///
  /// [request] - The HTTP request that failed.
  /// [exception] - The error that occurred during the request.
  /// [requestIdHeader] - Optional header name to retrieve the request ID.
  @mustCallSuper
  void logFailedRequest(BaseRequest request, Object exception, {String? requestIdHeader}) {
    final method = request.method;
    final url = request.url;
    final requestId = request.headers[requestIdHeader];
    final duration = _removeRequestReceiveTime(requestId)?.inMilliseconds;

    final String urlTag = url.toString();
    final String methodTag = '${method.toUpperCase()} Failed';
    final String? durationTag = duration != null ? '${duration}ms' : null;

    final List<String> additionalTags = [methodTag, urlTag, if (durationTag != null) durationTag];

    logError(
      '',
      error: exception,
      additionalTags: additionalTags,
    );
  }

  /// Logs an HTTP request.
  ///
  /// This method logs the details of an HTTP request, including the method,
  /// URL, and request ID (if provided). It also records the time the request
  /// was sent for later duration calculations.
  ///
  /// [request] - The HTTP request to log.
  /// [requestIdHeader] - Optional header name to retrieve the request ID.
  /// [additionalMessage] - Optional additional message to log.
  @mustCallSuper
  void logHttpRequest(Request request, {String? requestIdHeader, String? additionalMessage}) {
    final requestId = request.headers[requestIdHeader];
    final url = request.url;
    final method = request.method;

    if (requestId != null) {
      _writeRequestSendTime(requestId);
    }

    final String urlTag = url.toString();
    final String methodTag = '${method.toUpperCase()} Processed';

    final String messageText = [
      if (additionalMessage != null) additionalMessage,
    ].join('\n');
    final List<String> additionalTags = [methodTag, urlTag];

    logDebug(messageText, additionalTags: additionalTags);
  }

  /// Logs an HTTP response.
  ///
  /// This method logs the details of an HTTP response, including the method,
  /// URL, status code, and duration (if applicable). It logs as an error
  /// if the response indicates failure.
  ///
  /// [response] - The HTTP response to log.
  /// [requestIdHeader] - Optional header name to retrieve the request ID.
  @mustCallSuper
  void logHttpResponse(Response response, {String? requestIdHeader, String? additionalMessage}) {
    final Uri? url = response.request?.url;
    final String? requestId = response.request?.headers[requestIdHeader];
    final String method = response.request?.method.toUpperCase() ?? '';
    final String reason = response.reasonPhrase ?? '';
    final String body = response.body;
    final Duration? duration = _removeRequestReceiveTime(requestId);
    final int statusCode = response.statusCode;
    final bool isSuccessful = response.isSuccessful;

    final String urlTag = url != null ? url.toString() : '';
    final String? durationTag = duration != null ? '${duration.inMilliseconds}ms' : null;
    final String resultTag = '$method Completed $statusCode';

    final List<String> additionalTags = [resultTag, urlTag, if (durationTag != null) durationTag];
    final String messageText = [
      if (additionalMessage != null) additionalMessage,
      if (!isSuccessful) 'Fail reason: $reason\nResponse body: $body',
    ].join('\n');

    if (response.isSuccessful) {
      logDebug(messageText, additionalTags: additionalTags);
    } else {
      logError(messageText, additionalTags: additionalTags);
    }
  }

  /// Records the time an HTTP request was sent.
  ///
  /// This method saves the current UTC time associated with the provided request ID.
  ///
  /// [requestId] - The ID of the request to associate with the send time.
  void _writeRequestSendTime(String requestId) => requestsSendTime[requestId] = DateTime.now().toUtc();

  /// Removes the recorded send time for a request and calculates the duration.
  ///
  /// This method retrieves the time the request was sent and returns the duration
  /// since that time. If no time is recorded for the provided request ID, it returns null.
  ///
  /// [requestId] - The ID of the request to retrieve the send time for.
  Duration? _removeRequestReceiveTime(String? requestId) {
    final receiveTime = requestsSendTime[requestId];
    if (receiveTime == null) {
      return null;
    }
    return DateTime.now().toUtc().difference(receiveTime);
  }

  @protected
  Duration calculateReceiveDuration(DateTime time) => DateTime.now().toUtc().difference(time);
}

/// Extension on the [Response] class to determine if the response was successful.
extension on Response {
  /// Checks if the response indicates success.
  bool get isSuccessful => statusCode < 400;
}
