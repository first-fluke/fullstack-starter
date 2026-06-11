import 'package:dio/dio.dart';

/// {@template app_exception}
/// A sealed hierarchy of application-level exceptions.
/// {@endtemplate}
sealed class AppException implements Exception {
  /// {@macro app_exception}
  const AppException(this.message);

  /// Maps a [DioException] to the appropriate [AppException] subclass.
  factory AppException.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(e.message ?? 'Network error');
    }

    if (statusCode == 401) {
      return const UnauthorizedException('Unauthorized');
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException('Server error: $statusCode');
    }

    return UnknownException(e.message ?? 'Unknown error');
  }

  /// Human-readable description of the error.
  final String message;
}

/// Thrown when a network connectivity error occurs.
final class NetworkException extends AppException {
  /// Creates a [NetworkException].
  const NetworkException(super.message);
}

/// Thrown when the server returns a 401 Unauthorized response.
final class UnauthorizedException extends AppException {
  /// Creates an [UnauthorizedException].
  const UnauthorizedException(super.message);
}

/// Thrown when the server returns a 5xx response.
final class ServerException extends AppException {
  /// Creates a [ServerException].
  const ServerException(super.message);
}

/// Thrown for any error that does not fit the other categories.
final class UnknownException extends AppException {
  /// Creates an [UnknownException].
  const UnknownException(super.message);
}
