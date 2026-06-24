import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final String errorCode;
  final int statusCode;

  ApiException({
    required this.message,
    required this.errorCode,
    required this.statusCode,
  });

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return ApiException(
        message: body['message'] ?? 'Unexpected error occurred.',
        errorCode: body['errorCode'] ?? 'UNKNOWN_ERROR',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiException(
        message: 'Unexpected response from server. Please try again.',
        errorCode: 'FORMAT_EXCEPTION',
        statusCode: response.statusCode,
      );
    }
  }

  factory ApiException.network() {
    return ApiException(
      message: 'No internet connection. Please check your network.',
      errorCode: 'NETWORK_ERROR',
      statusCode: 0,
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      message: 'Request timed out. Please try again.',
      errorCode: 'TIMEOUT_ERROR',
      statusCode: 408,
    );
  }

  @override
  String toString() => message;
}
