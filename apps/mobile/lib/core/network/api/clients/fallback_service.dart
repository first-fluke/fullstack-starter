// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/health_response.dart';

part 'fallback_service.g.dart';

@RestApi()
abstract class FallbackService {
  factory FallbackService(Dio dio, {String? baseUrl}) = _FallbackService;

  /// Health Check.
  ///
  /// Detailed health check endpoint with service statuses.
  @GET('/health')
  Future<HealthResponse> healthCheckHealthGet();

  /// Liveness Check.
  ///
  /// Simple liveness probe for Kubernetes.
  @GET('/health/live')
  Future<Map<String, String>> livenessCheckHealthLiveGet();

  /// Readiness Check.
  ///
  /// Readiness probe - checks if app can serve traffic.
  @GET('/health/ready')
  Future<Map<String, String>> readinessCheckHealthReadyGet();
}
