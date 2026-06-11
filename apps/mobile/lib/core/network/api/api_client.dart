// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/fallback_service.dart';
import 'clients/authentication_service.dart';

/// fullstack-starter-api `v0.1.0`
class ApiClient {
  ApiClient(
    Dio dio, {
    String? baseUrl,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  FallbackService? _fallback;
  AuthenticationService? _authentication;

  FallbackService get fallback =>
      _fallback ??= FallbackService(_dio, baseUrl: _baseUrl);

  AuthenticationService get authentication =>
      _authentication ??= AuthenticationService(_dio, baseUrl: _baseUrl);
}
