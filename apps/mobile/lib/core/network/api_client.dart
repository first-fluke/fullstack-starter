import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_env.dart';

/// {@template api_client}
/// A client for making network requests.
/// {@endtemplate}
class ApiClient {
  /// {@macro api_client}
  ApiClient({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppEnv.current.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  /// The underlying [Dio] instance.
  Dio get dio => _dio;
}
