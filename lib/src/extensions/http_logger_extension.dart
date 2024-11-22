import 'package:adguard_logger/src/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

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
    final url = request.url.toString();
    final requestId = request.headers[requestIdHeader];
    final duration = _removeRequestReceiveTime(requestId)?.inMilliseconds;

    final requestIdMessage = requestId != null ? 'Id=$requestId' : '';

    logError(
      [
        '$method to $url failed${duration == null ? '.' : ' in ${duration}ms.'}',
        if (requestIdMessage.isNotEmpty) requestIdMessage,
      ].join('\n'),
      error: exception,
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
  @mustCallSuper
  void logHttpRequest(Request request, {String? requestIdHeader}) {
    final requestId = request.headers[requestIdHeader];
    if (requestId != null) {
      _writeRequestSendTime(requestId);
    }

    final message = _getMessageForRequest(request, requestId: requestId);
    logDebug(message);
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
  void logHttpResponse(Response response, {String? requestIdHeader}) {
    final message = _getMessageForResponse(response, requestIdHeader: requestIdHeader);
    if (message == null) {
      return;
    }
    if (response.isSuccessful) {
      logDebug(message);
    } else {
      logError(message);
    }
  }

  /// Constructs a message for an HTTP request.
  ///
  /// This method creates a formatted string message for the provided HTTP request.
  ///
  /// [request] - The HTTP request for which to generate a message.
  /// [requestId] - The request ID (if available).
  String _getMessageForRequest(Request request, {String? requestId}) {
    final url = request.url.toString();
    final method = request.method;
    final message = [
      '$method to $url',
      if (requestId != null) 'Id=$requestId',
    ].join('\n');

    return message;
  }

  /// Constructs a message for an HTTP response.
  ///
  /// This method creates a formatted string message for the provided HTTP response.
  ///
  /// [response] - The HTTP response for which to generate a message.
  /// [requestIdHeader] - Optional header name to retrieve the request ID.
  String? _getMessageForResponse(Response response, {String? requestIdHeader}) {
    final request = response.request;
    if (request == null) {
      return null;
    }

    final reason = response.reasonPhrase;
    final statusCode = response.statusCode;
    final isSuccessful = response.isSuccessful;

    final url = request.url.toString();
    final requestId = request.headers[requestIdHeader];
    final duration = _removeRequestReceiveTime(requestId);

    final durationMessage = duration != null ? ' in ${duration.inMilliseconds}ms.' : '.';
    final requestIdMessage = requestId != null ? 'Id=$requestId' : '';
    final method = request.method;

    final message = [
      '$method to $url completed$durationMessage.',
      if (requestIdMessage.isNotEmpty) requestIdMessage,
      'Status=$statusCode',
      if (!isSuccessful) ...[
        'Fail reason: $reason',
        if (response.body.isNotEmpty) 'Failed with server response: ${response.body}'
      ],
    ].join('\n');

    return message;
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
